import {Composition} from 'remotion';
import {ShortComposition, ShortPropsSchema} from './ShortComposition';

const FPS = 30;
const SHORT_DURATION_SEC = 55;
const WIDTH = 1080;
const HEIGHT = 1920;

export const RemotionRoot: React.FC = () => {
	return (
		<>
			<Composition
				id="ShortComposition"
				component={ShortComposition}
				durationInFrames={SHORT_DURATION_SEC * FPS}
				fps={FPS}
				width={WIDTH}
				height={HEIGHT}
				schema={ShortPropsSchema}
				defaultProps={{
					scenes: [
						{
							sceneId: 1,
							startSec: 0,
							endSec: 5,
							videoSrc: '',
							textOverlay: {
								text: 'Demo overlay — replace with real script',
								position: 'top-center',
								color: '#FFFFFF',
								stroke: '#000000',
								fontSize: 80,
							},
						},
					],
				}}
			/>
		</>
	);
};
