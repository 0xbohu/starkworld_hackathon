import create from 'zustand';
import { nanoid } from 'nanoid';

const getLocalStorage = (key) => null; // JSON.parse(window.localStorage.getItem(key));
const setLocalStorage = (key, value) =>
  window.localStorage.setItem(key, JSON.stringify(value));

export const useStore = create((set) => ({
  position: [0,0,0], // default cube position
  texture: 'glass', // default texture to render cubes
  cubes: getLocalStorage('world') || [],
  ground:[0,0,0,0,0],  // build ground x,y,z,w,h for switching to player build group
  surroundings:[], // surroundings lands
  cubehelper: [0,0,0],
  addCube: (x, y, z) =>
    set((state) => ({
      cubes: state.cubes.length < 150?
        state.cubes.filter((cube) => {
          const [_x, _y, _z] = cube.pos;
          return _x === x && _y === y && _z === z;
        }).length > 0 ?
        [
          ...state.cubes
        ]
        :
        [
          ...state.cubes,
          { key: nanoid(), pos: [x, y, z], texture: state.texture,size:[1,1,1],type:"cube"}
        ]
        :[
          ...state.cubes
        ]


    })
    
    
    ),
  removeCube: (x, y, z) => {
    set((state) => ({
      cubes: state.cubes.filter((cube) => {
        const [_x, _y, _z] = cube.pos;
        return _x !== x || _y !== y || _z !== z;
      }),
    }));
  },
  batchInitialCube: (items) => {
    set((state) => ({
        cubes: items
    }))
  },
  batchLoadCube: (items) => { //
    set((state) => ({
      cubes: [
        ...state.cubes,
        ...items
      ]
     
    }))
  },
  resetCubes: (items) => {
    set((state) => ({
        cubes: [],
    }))
  },

  updateGround: (x, y, z, w, h) =>
  set((state) => ({
    ground: [x, y, z,w, h ]
  })),


  updateSurroundings: (items) =>
  set((state) => ({
    surroundings: [
      ...state.surroundings,
      ...
       items.filter((item) => {  // concat new cubes if not exist 
              var foundInState = false;
              state.surroundings.forEach(function(cube,i){
                if(cube.group === item.group){
                  foundInState = true;
                }
              })
            return !foundInState;
          }),
    ]
  })),

  removeSurroundings: (landids) =>
  set((state) => ({
    surroundings: [
      ...
      state.surroundings.filter((surr) => {  // concat new cubes if not exist 
              var foundInState = false;
              landids.forEach(function(landid,i){
                if(surr.group === landid){
                  foundInState = true;
                }
              })
            return !foundInState;
          }),
    ]
  })),

  setTexture: (texture) => {
    set((state) => ({
      texture,
    }));
  },
  setPosition: (position) => {
    set((state) => ({
      position,
    }));
  },
  saveWorld: () =>
    set((state) => {
      setLocalStorage('world', state.cubes);
    }),
}));
