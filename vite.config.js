import { defineConfig, loadEnv } from 'vite';
import laravel from 'laravel-vite-plugin';
import { viteStaticCopy } from 'vite-plugin-static-copy';
import purgecss from 'vite-plugin-purgecss';

export default defineConfig(({ mode }) => {
    const env = loadEnv(mode, process.cwd(), '');

    return {
        plugins: [
            laravel({
                input: [
                    'resources/sass/app.scss',
                    'resources/js/app.js',
                    'resources/js/flatpickr.js',
                    'resources/js/tinymce.js',
                ],
                refresh: true,
            }),
            viteStaticCopy({
                targets: [
                    { src: 'node_modules/tinymce/icons', dest: 'js', rename: { stripBase: 2 } },
                    { src: 'node_modules/tinymce/models', dest: 'js', rename: { stripBase: 2 } },
                    { src: 'node_modules/tinymce/themes', dest: 'js', rename: { stripBase: 2 } },
                    { src: 'node_modules/tinymce/skins', dest: 'js', rename: { stripBase: 2 } },
                ],
            }),
            purgecss({
                content: [
                    './resources/views/**/*.blade.php',
                    './resources/js/**/*.js',
                    './vendor/laravel/framework/src/Illuminate/Pagination/resources/views/*bootstrap-5.blade.php',
                ],
                safelist: {
                    deep: [/\b(ui|flatpickr)-\S*$/, /^swal2-/, /ts-/],
                },
            }),
        ],
        css: {
            preprocessorOptions: {
                scss: {
                    additionalData:
                        // VATSSA: brand background. Drives the navbar and every primary button.
                        '$envColorPrimary: ' + (env.BOOTSTRAP_COLOR_PRIMARY || '#07262C') + '; ' +
                        '$envColorSecondary: ' + (env.BOOTSTRAP_COLOR_SECONDARY || '#95a5a6') + '; ' +
                        // VATSSA: teal — navbar hover/active state.
                        '$envColorTertiary: ' + (env.BOOTSTRAP_COLOR_TERTIARY || '#0197B0') + '; ' +
                        // VATSSA: teal — informational actions (Edit, Book Now, Send E-mail).
                        '$envColorInfo: ' + (env.BOOTSTRAP_COLOR_INFO || '#0197B0') + '; ' +
                        // VATSSA: green — positive actions and pagination, which
                        // Bootswatch Flatly derives from $success.
                        '$envColorSuccess: ' + (env.BOOTSTRAP_COLOR_SUCCESS || '#7BD758') + '; ' +
                        '$envColorWarning: ' + (env.BOOTSTRAP_COLOR_WARNING || '#F39C12') + '; ' +
                        // Deeper red than Flatly's #E74C3C — reads better against #07262C.
                        // Deliberately not a brand colour: destructive actions must not blend in.
                        '$envColorDanger: ' + (env.BOOTSTRAP_COLOR_DANGER || '#C0392B') + ';',
                },
            },
        },
    };
});
