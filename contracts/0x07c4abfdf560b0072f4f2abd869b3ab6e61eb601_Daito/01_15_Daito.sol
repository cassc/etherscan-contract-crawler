// SPDX-License-Identifier: MIT
//
//
// Twitter: https://twitter.com/bushidosnft
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./BushidoInterface.sol";

contract Daito is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public constant MAX_DAITO = 8888;
    bool public mintIsActive = false;
    string public baseTokenURI;

    mapping (uint256 => uint256) private _bushidoUsed;

    address public BUSHIDO_ADDRESS = 0xd2AAd45015090F8d45ad78E456B58dd61Fb7cD79;
    BushidoInterface bushidoContract = BushidoInterface(BUSHIDO_ADDRESS);

    constructor(string memory baseURI) ERC721("Daito", "DAITO") {
        setBaseURI(baseURI);
    }

    //User Function to Claim
    function mintDaito(uint256[] memory bushidoIds) public {

        require(mintIsActive, "Must be active to mint Daitos");

        uint numberOfDaitos = (bushidoIds.length);
        uint256 currentSupply = _tokenSupply.current();

        require(currentSupply.add(numberOfDaitos) <= MAX_DAITO, "Mint would exceed max supply of Daitos");

        for (uint256 i = 0; i < bushidoIds.length; i++) {
            uint256 bushidoId = bushidoIds[i];
            require(canMintWithBushido(bushidoId) && bushidoContract.ownerOf(bushidoId) == msg.sender, "Bad owner!");
            _bushidoUsed[bushidoId] = 1; 
            uint256 mintIndex = _tokenSupply.current();       
            _safeMint(msg.sender, mintIndex);
            _tokenSupply.increment();  
        }
    }

    function canMintWithBushido(uint256 bushidoId) public view returns(bool) {
        return _bushidoUsed[bushidoId] == 0;
    }

    //Only owner actions
    //Turn sale active
    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    // internal function override
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // set baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    //Witdraw funds
    function withdrawAll() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    //See how many sashimono claimed
    function totalClaimed() public view returns (uint256) {
        return _tokenSupply.current();
    }
}