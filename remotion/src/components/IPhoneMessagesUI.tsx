// iPhone Messages app overlay — for style_signature = "iphone-imessage-narration"
// Renders a fake Messages conversation that scrolls in sync with voiceover.

import {AbsoluteFill, useCurrentFrame, useVideoConfig, interpolate} from 'remotion';

export interface IMessage {
	from: 'me' | 'other';
	text: string;
	atSec: number; // when this message appears
}

export interface IPhoneMessagesProps {
	contactName: string;
	messages: IMessage[];
	backgroundColor?: string; // behind the phone (solid color or gradient)
}

const BUBBLE_ME_BG = '#0B93F6';
const BUBBLE_OTHER_BG = '#E5E5EA';
const TEXT_ME = '#FFFFFF';
const TEXT_OTHER = '#000000';

export const IPhoneMessagesUI: React.FC<IPhoneMessagesProps> = ({contactName, messages, backgroundColor = '#1a1a1a'}) => {
	const frame = useCurrentFrame();
	const {fps} = useVideoConfig();
	const currentSec = frame / fps;

	// Show only messages whose atSec <= currentSec
	const visible = messages.filter((m) => m.atSec <= currentSec);

	// Auto-scroll: simulate bottom-pinning as messages stack
	const scrollOffset = Math.max(0, visible.length * 90 - 800); // each msg ~ 90px tall, viewport 800px

	return (
		<AbsoluteFill style={{backgroundColor, justifyContent: 'center', alignItems: 'center'}}>
			{/* iPhone bezel */}
			<div
				style={{
					width: 720,
					height: 1500,
					backgroundColor: '#000',
					borderRadius: 60,
					padding: 12,
					boxShadow: '0 0 60px rgba(0,0,0,0.5)',
				}}
			>
				{/* Screen */}
				<div
					style={{
						width: '100%',
						height: '100%',
						backgroundColor: '#FFFFFF',
						borderRadius: 50,
						overflow: 'hidden',
						display: 'flex',
						flexDirection: 'column',
					}}
				>
					{/* Header bar */}
					<div
						style={{
							height: 100,
							backgroundColor: '#F8F8F8',
							borderBottom: '1px solid #E0E0E0',
							display: 'flex',
							justifyContent: 'center',
							alignItems: 'center',
							flexDirection: 'column',
							fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif',
							fontSize: 32,
							fontWeight: 600,
						}}
					>
						{contactName}
					</div>

					{/* Messages area */}
					<div
						style={{
							flex: 1,
							padding: '20px 16px',
							overflow: 'hidden',
							position: 'relative',
						}}
					>
						<div style={{transform: `translateY(${-scrollOffset}px)`, transition: 'transform 200ms'}}>
							{visible.map((m, i) => {
								const ageFrames = Math.round((currentSec - m.atSec) * fps);
								const scaleIn = ageFrames < 8 ? interpolate(ageFrames, [0, 8], [0.7, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}) : 1;
								const opacityIn = ageFrames < 8 ? interpolate(ageFrames, [0, 8], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'}) : 1;
								return (
									<div
										key={i}
										style={{
											display: 'flex',
											justifyContent: m.from === 'me' ? 'flex-end' : 'flex-start',
											marginBottom: 14,
											transform: `scale(${scaleIn})`,
											opacity: opacityIn,
										}}
									>
										<div
											style={{
												maxWidth: '70%',
												backgroundColor: m.from === 'me' ? BUBBLE_ME_BG : BUBBLE_OTHER_BG,
												color: m.from === 'me' ? TEXT_ME : TEXT_OTHER,
												padding: '14px 20px',
												borderRadius: 24,
												fontSize: 30,
												lineHeight: 1.3,
												fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
											}}
										>
											{m.text}
										</div>
									</div>
								);
							})}
						</div>
					</div>

					{/* Bottom bar (input area) */}
					<div
						style={{
							height: 80,
							borderTop: '1px solid #E0E0E0',
							backgroundColor: '#F8F8F8',
						}}
					/>
				</div>
			</div>
		</AbsoluteFill>
	);
};
