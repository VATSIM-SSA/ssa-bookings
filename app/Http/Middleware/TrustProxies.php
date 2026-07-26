<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Illuminate\Http\Middleware\TrustProxies as Middleware;

class TrustProxies extends Middleware
{
    /**
     * The trusted proxies for this application.
     *
     * VATSSA: '*' — Cloudflare terminates TLS, then the tunnel + Caddy talk
     * plain HTTP internally, so Laravel must trust the X-Forwarded-Proto header
     * to generate https:// URLs. Without this, OAuth builds an http:// redirect
     * and Handover/VATSIM returns invalid_client. Safe because the container has
     * no host ports — only Caddy reaches it. Pairs with Caddy's
     * `header_up X-Forwarded-Proto https`. See ssa-ovh-management vps-status.md.
     *
     * @var array|string|null
     */
    protected $proxies = '*';

    /**
     * The headers that should be used to detect proxies.
     *
     * @var int
     */
    protected $headers =
    Request::HEADER_X_FORWARDED_FOR |
        Request::HEADER_X_FORWARDED_HOST |
        Request::HEADER_X_FORWARDED_PORT |
        Request::HEADER_X_FORWARDED_PROTO |
        Request::HEADER_X_FORWARDED_AWS_ELB;
}
