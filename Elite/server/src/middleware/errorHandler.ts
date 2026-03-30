import type { FastifyInstance, FastifyError } from 'fastify';

interface AppError extends Error {
  statusCode?: number;
  code?: string;
}

export function setErrorHandler(app: FastifyInstance): void {
  app.setErrorHandler((error: FastifyError | AppError, request, reply) => {
    const statusCode = resolveStatusCode(error);
    const message = resolveMessage(error, statusCode);

    request.log.error({
      err: error,
      statusCode,
      url: request.url,
      method: request.method,
    });

    return reply.code(statusCode).send({
      error: message,
      statusCode,
    });
  });
}

function resolveStatusCode(error: FastifyError | AppError): number {
  // Fastify validation errors
  if ('validation' in error && error.validation) {
    return 400;
  }

  // Explicit status code on the error
  if (error.statusCode) {
    return error.statusCode;
  }

  // PostgreSQL error codes
  if ('code' in error && typeof error.code === 'string') {
    switch (error.code) {
      case '23505': // unique_violation
        return 409;
      case '23503': // foreign_key_violation
        return 400;
      case '23502': // not_null_violation
        return 400;
      case '22P02': // invalid_text_representation (bad UUID, etc.)
        return 400;
      default:
        break;
    }
  }

  return 500;
}

function resolveMessage(error: FastifyError | AppError, statusCode: number): string {
  // Known PostgreSQL constraint violations
  if ('code' in error && typeof error.code === 'string') {
    switch (error.code) {
      case '23505':
        return 'Resource already exists';
      case '23503':
        return 'Referenced resource not found';
      case '23502':
        return 'Missing required field';
      case '22P02':
        return 'Invalid data format';
    }
  }

  // Fastify rate limit
  if (statusCode === 429) {
    return 'Too many requests. Please try again later.';
  }

  // Never leak internal error details in production
  if (statusCode >= 500) {
    return process.env['NODE_ENV'] === 'production'
      ? 'Internal server error'
      : error.message;
  }

  return error.message;
}
