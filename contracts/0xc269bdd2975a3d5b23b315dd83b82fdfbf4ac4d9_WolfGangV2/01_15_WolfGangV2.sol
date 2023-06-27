pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";

contract WolfGangV2 is ERC721, AccessControl {
    using SafeMath for uint;
    
    bool public hasSaleStarted = false;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    ERC721 _wolfGangV1 = ERC721(0x88c2b948749b13aBC1e0AE4B50ebeb2131D283C1);
    
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Restricted to admins.");
        _;
    }
    
    constructor(string memory baseURI) ERC721("The WolfGang", "WOLF", _wolfGangV1) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function mint(address receiver) external onlyAdmin returns (uint){
        uint tokenId = _nextTokenId++;
        _safeMint(receiver, tokenId);
        return tokenId;
    }

    function setBaseURI(string memory baseURI) public onlyAdmin {
        _setBaseURI(baseURI);
    }
    
    function burn(uint tokenId) external onlyAdmin {
        _burn(tokenId);
    }
}