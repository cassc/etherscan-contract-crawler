/* SPDX-License-Identifier: MIT
          _____                   _______                   _____                    _____          
         /\    \                 /::\    \                 /\    \                  /\    \         
        /::\    \               /::::\    \               /::\____\                /::\    \        
        \:::\    \             /::::::\    \             /::::|   |               /::::\    \       
         \:::\    \           /::::::::\    \           /:::::|   |              /::::::\    \      
          \:::\    \         /:::/~~\:::\    \         /::::::|   |             /:::/\:::\    \     
           \:::\    \       /:::/    \:::\    \       /:::/|::|   |            /:::/__\:::\    \    
            \:::\    \     /:::/    / \:::\    \     /:::/ |::|   |           /::::\   \:::\    \   
             \:::\    \   /:::/____/   \:::\____\   /:::/  |::|   | _____    /::::::\   \:::\    \  
              \:::\    \ |:::|    |     |:::|    | /:::/   |::|   |/\    \  /:::/\:::\   \:::\    \ 
_______________\:::\____\|:::|____|     |:::|    |/:: /    |::|   /::\____\/:::/  \:::\   \:::\____\
\::::::::::::::::::/    / \:::\    \   /:::/    / \::/    /|::|  /:::/    /\::/    \:::\  /:::/    /
 \::::::::::::::::/____/   \:::\    \ /:::/    /   \/____/ |::| /:::/    /  \/____/ \:::\/:::/    / 
  \:::\~~~~\~~~~~~          \:::\    /:::/    /            |::|/:::/    /            \::::::/    /  
   \:::\    \                \:::\__/:::/    /             |::::::/    /              \::::/    /   
    \:::\    \                \::::::::/    /              |:::::/    /               /:::/    /    
     \:::\    \                \::::::/    /               |::::/    /               /:::/    /     
      \:::\    \                \::::/    /                /:::/    /               /:::/    /      
       \:::\____\                \::/____/                /:::/    /               /:::/    /       
        \::/    /                 ~~                      \::/    /                \::/    /        
         \/____/                                           \/____/                  \/____/                                                                                                             
*/

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "./interfaces/IZooOfNeuralAutomata.sol";
import {INeuralAutomataEngine, NCAParams} from "./interfaces/INeuralAutomataEngine.sol";
import {ERC1155} from "../lib/solmate/src/tokens/ERC1155.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {Base64} from "./utils/Base64.sol";

contract ZooOfNeuralAutomata is IZooOfNeuralAutomata, ERC1155, Owned {

    string public name = "Zoo of Neural Automata";
    string public symbol = "ZoNA";
    string public contractURI;

    address public engine;
 
    mapping(uint256 => NCAParams) public tokenParams;
    mapping(uint256 => address) public tokenMinter;
    mapping(uint256 => address) public tokenBurner;
    mapping(uint256 => string) public tokenBaseURI;
    mapping(uint256 => bool) public tokenFrozen;

    modifier onlyUnfrozen(uint256 _id){
        require(!tokenFrozen[_id]);
        _;
    }

    constructor(
        address _engine, 
        string memory _contractURI
    ) Owned(msg.sender) {
        engine = _engine;
        contractURI = _contractURI;
    }

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenParams[_id] = _params;
        tokenMinter[_id] = _minter;
        tokenBurner[_id] = _burner;
        tokenBaseURI[_id] = _baseURI;
    }

    function updateParams(
        uint256 _id, 
        NCAParams memory _params
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenParams[_id] = _params;
    }

    function updateMinter(
        uint256 _id, 
        address _minter
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenMinter[_id] = _minter;
    }

    function updateBurner(
        uint256 _id, 
        address _burner
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenBurner[_id] = _burner;
    }

    function updateBaseURI(
        uint256 _id, 
        string memory _baseURI
    ) external onlyOwner onlyUnfrozen(_id) {
        tokenBaseURI[_id] = _baseURI;
    }

    function freeze(uint256 _id) external onlyOwner {
        tokenFrozen[_id] = true;
    }

    function updateEngine(address _engine) external onlyOwner  {
        engine = _engine;
    }

    function updateContractURI(string memory _contractURI) external onlyOwner  {
        contractURI = _contractURI;
    } 

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external {
        require(msg.sender == tokenMinter[_id]);
        _mint(_to, _id, _amount, "");
    }

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external {
        require(msg.sender == tokenBurner[_id]);
        _burn(_from, _id, _amount);
    }

    function uri(uint256 id) public view override returns (string memory){
        require(tokenMinter[id] != address(0));
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    string.concat(
                        tokenBaseURI[id],
                        "\"",
                        INeuralAutomataEngine(engine).page(tokenParams[id]),
                        "\"}"
                    )
                )
            )
        );
    }

}