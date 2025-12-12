#!/bin/sh
# Health check ping for QuizPro production server with timestamps

echo
echo "render status for quizpro-production server"
echo

echo "Ping sent: $(date '+%Y-%m-%d %H:%M:%S')"
echo
curl https://quizpro-api-9xn4.onrender.com/healthz
echo
echo "Ping complete: $(date '+%Y-%m-%d %H:%M:%S')"
echo

