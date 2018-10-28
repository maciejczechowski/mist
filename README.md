# mISSt (aka Modern ISS Tracker)

Your Dad's an astronaut and you don't know when to wave him?

Ever wondered if this bright thing you see is an Alien spaceship or just a piece of human technology?

Now you can! Modern ISS Tracker will show you the current position of International Space Station so you always now what the big bright dot on your sky is.

## Building
 mISSt uses Carthage for dependency management, so make sure you have that installed. You will also need your personalized Mapbox API Key.

 1. Clone the repository
 1. Run `carthage update` to get all the dependencies
 1. Put your Mapbox key in `Info.plist` under `MGLMapboxAccessToken` Key
 1. Build and run!
