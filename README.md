# Space-Explorer
A simple game where you need to seek fuel while evading asteroid. Created using RayLib and Odin. Trying out a new language and implementing my own GJK algorithm.

## Premise
You are a ship that is low on fuel. Trying to survive...
You try and gather fuel scattered on the space while trying to manouver your way around the asteroids.
Your ships gets more out-of control the more you play thus faster and make it harder to evade.

## Controls
Arrow Keys (left and right) to turn the ship

## GJK Algorithm
This was my first attempt at tackling GJK algorithm. I have a few debug mode in the game to allow me to test and understand more about the GJK algorithm.
Here are the list of them

Usable during game mode :
Key D : Enable local space drawing relative to the ship. This was originally to debug local space transform for asteroid. But it looks relatively cool as it's a lot like radar. So I decided to keep it :p

### GJK Hit Test mode:
GJK Hit test mode will make you go to seperate section. Where I do my prototype/proof of concept of GJK Algorithm. To access this, you can press TAB.
Note : To switch back into the game, just press TAB again

In this mode there's 5 submode :
1. Hit-Test mode (this is the default mode)
Here you can visualize the GJK algorithm by stepping through the algorithm using the A and D key.
2. Insert Polygon A Mode
To enter this mode use the I key. Here you can clear the current points using the C key. Clicking the mouse will add a new point on your current mouse position.
Enter will commit your shape and go in to Sub-mode 1.
3. Insert Polygon B Mode
To enter this mode use the Shift+I key. The controls are pretty similar to the 2nd submode. But this will modify the 2nd shape.
4. Edit Polygon A Mode
To enter this mode use the E key. The current modify point is pointed by the index. The A and D key will cycle the index. Clicking the mouse will move the currently edited point to your mouse location. Pressing Enter or Escape will go into Sub-mode 1.
5. Edit Polygon B Mode
To enter this mode use the Shift+E key. The controls are pretty similar to the 4th submode. But this will modify the 2nd shape.

## ODIN
The game is built using Odin. This is my first project using the language. At first, I was trying to create this project using C + Raylib. But things quickly went a bit troublesome when I try to do local/space transform using C, as in C you cannot do operator overloading. So going into Odin, I really like the built in vector operators, matrices, and all that stuff. It really feels like C with more quality of life. I really like the balance. I come from heavy IDE backgrounds like Jetbrain or Visual Studio So going into Odin, I really like the built in vector operators, matrices, and all that stuff. It really feels like C with more quality of life. I really like the balance. I come from heavy IDE backgrounds like Jetbrain or Visual Studio. So I really miss the refactoring language feature like renaming variables, Finding all usages of functions/procedure, etc. I don't think the language server has these features yet? although I could be wrong. As I use pretty much what's available in the vscode-extension store.

Procedure Group is something that I definitely want in a language like C. It's really function overloading but controlled.

So far, I really like the language. 