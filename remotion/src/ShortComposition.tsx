import {AbsoluteFill, OffthreadVideo, Sequence, useVideoConfig, interpolate, spring, useCurrentFrame} from 'remotion';
import {z} from 'remotion';

export const TextOverlaySchema = z.object({
	text: z.string(),
	position: z.enum(['top-center', 'center', 'bottom-center', 'top-left', 'top-right', 'bottom-left', 'bottom-right']).default('top-center'),
	color: z.string().default('#FFFFFF'),
	stroke: z.string().default('#000000'),
	fontSize: z.number().default(80),
});

export const SceneSchema = z.object({
	sceneId: z.number(),
	startSec: z.number(),
	endSec: z.number(),
	videoSrc: z.string(),
	textOverlay: TextOverlaySchema.optional(),
});

export const ShortPropsSchema = z.object({
	scenes: z.array(SceneSchema),
});

type ShortProps = z.infer<typeof ShortPropsSchema>;
type SceneProps = z.infer<typeof SceneSchema>;

const positionStyles: Record<string, React.CSSProperties> = {
	'top-center': {top: '12%', left: 0, right: 0, textAlign: 'center'},
	center: {top: '45%', left: 0, right: 0, textAlign: 'center'},
	'bottom-center': {bottom: '15%', left: 0, right: 0, textAlign: 'center'},
	'top-left': {top: '12%', left: '6%', textAlign: 'left'},
	'top-right': {top: '12%', right: '6%', textAlign: 'right'},
	'bottom-left': {bottom: '15%', left: '6%', textAlign: 'left'},
	'bottom-right': {bottom: '15%', right: '6%', textAlign: 'right'},
};

const Scene: React.FC<{scene: SceneProps}> = ({scene}) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();

	const overlay = scene.textOverlay;
	const overlayScale = overlay
		? spring({frame: frame - 4, fps, config: {damping: 12, stiffness: 200}})
		: 1;

	return (
		<AbsoluteFill style={{backgroundColor: 'black'}}>
			{scene.videoSrc ? (
				<OffthreadVideo src={scene.videoSrc} muted />
			) : (
				<AbsoluteFill style={{backgroundColor: '#1a1a1a', justifyContent: 'center', alignItems: 'center'}}>
					<div style={{color: '#888', fontSize: 36}}>scene {scene.sceneId} — no video</div>
				</AbsoluteFill>
			)}
			{overlay ? (
				<AbsoluteFill style={{padding: '0 5%'}}>
					<div
						style={{
							position: 'absolute',
							...positionStyles[overlay.position],
							fontFamily: 'Impact, "Anton", sans-serif',
							fontWeight: 900,
							fontSize: overlay.fontSize,
							color: overlay.color,
							textShadow: `4px 4px 0 ${overlay.stroke}, -4px -4px 0 ${overlay.stroke}, 4px -4px 0 ${overlay.stroke}, -4px 4px 0 ${overlay.stroke}`,
							transform: `scale(${overlayScale})`,
							letterSpacing: '2px',
							textTransform: 'uppercase',
							lineHeight: 1.1,
						}}
					>
						{overlay.text}
					</div>
				</AbsoluteFill>
			) : null}
		</AbsoluteFill>
	);
};

export const ShortComposition: React.FC<ShortProps> = ({scenes}) => {
	const {fps} = useVideoConfig();
	return (
		<AbsoluteFill style={{backgroundColor: 'black'}}>
			{scenes.map((scene) => {
				const fromFrame = Math.round(scene.startSec * fps);
				const durationFrames = Math.max(1, Math.round((scene.endSec - scene.startSec) * fps));
				return (
					<Sequence key={scene.sceneId} from={fromFrame} durationInFrames={durationFrames}>
						<Scene scene={scene} />
					</Sequence>
				);
			})}
		</AbsoluteFill>
	);
};
