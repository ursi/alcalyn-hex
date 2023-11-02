import { Router } from 'express';
import { getManifest } from './manifest-manager';

export function pagesRouter() {
    const router = Router();

    // Render main page for any routes for html5 navigation
    router.get('/**', async (_, res) => {
        const manifest = await getManifest();

        const umami = {
            websiteId: process.env.UMAMI_WEBSITE_ID,
            src: process.env.UMAMI_SRC,
            domains: process.env.UMAMI_DOMAINS,
            hostUrl: process.env.UMAMI_HOST_URL,
        };

        res.render('page.ejs', {
            manifest,
            umami,
        });
    });

    return router;
}
