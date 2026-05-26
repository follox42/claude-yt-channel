// Generic vertical Short composition — text overlays on assets.
// Used when style_signature.production_recipe.primary_tool = "remotion"
// and the style is "stock-footage-narration" or "cartoon-flat".

import {AbsoluteFill, OffthreadVideo, Img, Sequence, useCurrentFrame, useVideoConfig, interpolate, spring} from 'remotion';

export interface SceneProps {
	sceneId: number;
	startSec: number;
	endSec: number;
	videoSrc?: string;
	imageSrc?: string;
	textOverlay?: {
		text: string;
		position: 'top-center' | 'center' | 'bottom-center' | 'top-left' | 'top-right';
		color: string;
		stroke: string;
		fontSize: number;
		animation: 'pop-spring' | 'slide-up' | 'type-on' | 'fade-in' | 'none';
		highlightWord?: string;
		highlightColor?: string;
	};
	transitionIn?: 'cut' | 'fade' | 'slide-left' | 'zoom' | 'glitch';
	kenBurns?: boolean; // slow zoom for still images
}

const positionStyles: Record<string, React.CSSProperties> = {
	'top-center': {top: '8%', left: 0, right: 0, textAlign: 'center'},
	center: {top: '40%', left: 0, right: 0, textAlign: 'center'},
	'bottom-center': {bottom: '20%', left: 0, right: 0, textAlign: 'center'},
	'top-left': {top: '8%', left: '6%', textAlign: 'left'},
	'top-right': {top: '8%', right: '6%', textAlign: 'right'},
};

export const Scene: React.FC<{scene: SceneProps}> = ({scene}) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const overlay = scene.textOverlay;

	// Animation progress
	let overlayScale = 1;
	let overlayOpacity = 1;
	let overlayY = 0;
	if (overlay && overlay.animation === 'pop-spring') {
		overlayScale = spring({frame: frame - 4, fps, config: {damping: 12, stiffness: 200}});
	} else if (overlay && overlay.animation === 'slide-up') {
		overlayY = interpolate(frame, [0, 15], [50, 0], {extrapolateRight: 'clamp'});
		overlayOpacity = interpolate(frame, [0, 15], [0, 1], {extrapolateRight: 'clamp'});
	} else if (overlay && overlay.animation === 'fade-in') {
		overlayOpacity = interpolate(frame, [0, 15], [0, 1], {extrapolateRight: 'clamp'});
	}

	// Ken Burns
	const kbScale = scene.kenBurns ? interpolate(frame, [0, 150], [1, 1.15], {extrapolateRight: 'clamp'}) : 1;

	return (
		<AbsoluteFill style={{backgroundColor: 'black'}}>
			{scene.videoSrc ? (
				<OffthreadVideo src={scene.videoSrc} muted style={{transform: `scale(${kbScale})`}} />
			) : scene.imageSrc ? (
				<Img src={scene.imageSrc} style={{width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${kbScale})`}} />
			) : (
				<AbsoluteFill style={{backgroundColor: '#1a1a1a', justifyContent: 'center', alignItems: 'center'}}>
					<div style={{color: '#888', fontSize: 36}}>scene {scene.sceneId} — no media</div>
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
							transform: `scale(${overlayScale}) translateY(${overlayY}px)`,
							opacity: overlayOpacity,
							letterSpacing: '2px',
							textTransform: 'uppercase',
							lineHeight: 1.1,
						}}
					>
						{overlay.highlightWord
							? overlay.text.split(' ').map((w, i) => (
									<span
										key={i}
										style={{
											color: w.toLowerCase().includes(overlay.highlightWord!.toLowerCase())
												? overlay.highlightColor || '#FFD700'
												: overlay.color,
										}}
									>
										{w}{' '}
									</span>
							  ))
							: overlay.text}
					</div>
				</AbsoluteFill>
			) : null}
		</AbsoluteFill>
	);
};

export const TextOverlayShort: React.FC<{scenes: SceneProps[]}> = ({scenes}) => {
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
