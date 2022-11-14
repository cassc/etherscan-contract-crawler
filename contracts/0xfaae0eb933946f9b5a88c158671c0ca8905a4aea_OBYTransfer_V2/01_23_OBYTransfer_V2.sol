// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import "./OBYToken.sol";
import "./BlackSquareNFT.sol";


contract OBYTransfer_V2 {
    using Strings for uint256;

    OBYToken obyToken;
    BlackSquareNFT blackSquare;

    uint256 constant OBY_PER_CYCLE = 300;

    address owner;
    address blacksquareAddress;

    bool public claimable;

    mapping(uint256 => bool) private _claimedInCycle;
    mapping(address => bool) private _eligibles;

    mapping (uint256 => bool) private _claimed;

    event RewardWithdrawn(uint256 amount, address sender);

    constructor(address _blackSquareAddress, address _obyAddress, bool _claimable) {
        blackSquare = BlackSquareNFT(_blackSquareAddress);
        obyToken = OBYToken(_obyAddress);
        owner = msg.sender;
        claimable = _claimable;
        blacksquareAddress = _blackSquareAddress;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OBYTransfer: caller is not eligible");
        _;
    }

    modifier onlyEligible() {
        require(owner == msg.sender || _eligibles[msg.sender ] == true, "IlluminaNFT: caller is not eligible");
        _;
    }

    function setEligibles(address _eligible) public onlyOwner {
        _eligibles[_eligible] = true;
    }

    function setClaimable (bool _claimable) public onlyEligible {
        claimable = _claimable;
    }

    function setClaimed (bool _claimable, uint256 _tokenId) public onlyEligible {
        _claimed[_tokenId] = _claimable;
    }


    function getOwnerOf (uint256 _tokenId) public view returns (address) {
        IERC721 nft = IERC721(blacksquareAddress);
        address tokenOwner = nft.ownerOf(_tokenId);

        return tokenOwner;
    }


    function transferOBYPerToken(uint256 _tokenId) external {
        
        if (getOwnerOf(_tokenId) == msg.sender && !_claimed[_tokenId] && claimable) {
            obyToken.mint(msg.sender, OBY_PER_CYCLE);
            _claimed[_tokenId] = true;
            emit RewardWithdrawn(OBY_PER_CYCLE, msg.sender);
        }

        emit RewardWithdrawn(0, msg.sender);
    }

    function getAlreadyClaimed(uint256 _tokenId) public view returns (bool) {
        if (_claimed[_tokenId]) {
            bool claimed = _claimed[_tokenId];
            return claimed;
        }

        return false;
        
    }

    function getTransferableOBYPerToken(uint256 _tokenId) external view returns (uint256) {
        if (getOwnerOf(_tokenId) == msg.sender && !_claimed[_tokenId] && claimable) {
            return OBY_PER_CYCLE;
        }
        return 0;
    }



    function transferOBYForAllTokensHeld() external {
        uint256[] memory tokens = blackSquare.getTokensHeldByUser(msg.sender);

        uint256 transferableOBY = 0;

        if (tokens.length > 0) {

            for (uint256 i = 0; i < tokens.length; i++ ) {
                uint256 tokenId = tokens[i];
                if (getOwnerOf(tokenId) == msg.sender && !_claimed[tokenId] && claimable) {
                    transferableOBY += OBY_PER_CYCLE;
                    _claimed[tokenId] = true;
                }
            }
        }

        if (transferableOBY > 0) {
            obyToken.mint(msg.sender, transferableOBY);
        }

        emit RewardWithdrawn(transferableOBY, msg.sender);
    }

    function getTransferableOBYForAllTokensHeld() external view returns (uint256) {
        uint256[] memory tokens = blackSquare.getTokensHeldByUser(msg.sender);

        uint256 transferableOBY = 0;

        if (tokens.length > 0) {

            for (uint256 i = 0; i < tokens.length; i++ ) {
                uint256 tokenId = tokens[i];
                if (getOwnerOf(tokenId) == msg.sender && !_claimed[tokenId] && claimable) {
                    transferableOBY += OBY_PER_CYCLE;
                }
            }
        }
        return transferableOBY;
    }
}