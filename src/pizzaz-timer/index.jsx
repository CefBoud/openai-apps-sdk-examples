import React from "react";
import { createRoot } from "react-dom/client";

const MIN_TIME_MINUTES = 15;
const MAX_TIME_MINUTES = 30;

function App() {

  // use widgetState.timeLeft if defined (saved previous state), otherwise pick a random duration
  const [timeLeft, setTimeLeft] = React.useState(window?.openai?.widgetState?.timeLeft ?? (Math.floor(Math.random() * (MAX_TIME_MINUTES - MIN_TIME_MINUTES + 1)) + MIN_TIME_MINUTES) * 60);

  React.useEffect(() => {
    if (timeLeft <= 0) return;
    const timer = setInterval(() => {
      setTimeLeft(prev => {
        const newTime = prev - 1;
        console.log("window?.openai?.widgetState", window?.openai?.widgetState)
        window?.openai?.setWidgetState((previous) => ({ timeLeft: newTime }));
        return newTime;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, [timeLeft]);

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;

  return (
    <div className="antialiased w-full text-black px-4 pb-2 border border-black/10 rounded-2xl sm:rounded-3xl overflow-hidden bg-white">
      <div className="max-w-full">
        <div className="flex flex-col items-center justify-center py-8">
          <div className="text-base sm:text-xl font-medium mb-4">
            Pizza Timer
          </div>
          <div className="text-4xl sm:text-6xl font-bold text-[#F46C21]">
            {minutes.toString().padStart(2, '0')}:{seconds.toString().padStart(2, '0')}
          </div>
          <div className="text-sm text-black/60 mt-2">
            Your pizza will be ready soon!
          </div>
        </div>
      </div>
    </div>
  );
}

createRoot(document.getElementById("pizzaz-timer-root")).render(<App />);