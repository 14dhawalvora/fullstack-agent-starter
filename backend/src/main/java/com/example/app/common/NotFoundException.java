package com.example.app.common;

/** Maps to HTTP 404. Also used when a record exists but belongs to someone else (don't leak existence). */
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) {
        super(message);
    }
}
