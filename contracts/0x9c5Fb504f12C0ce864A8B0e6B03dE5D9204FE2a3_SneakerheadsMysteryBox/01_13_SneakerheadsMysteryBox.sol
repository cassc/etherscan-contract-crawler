// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/* 
      ________  ___      ___  _______   
     /"       )|"  \    /"  ||   _  "\  
    (:   \___/  \   \  //   |(. |_)  :) 
     \___  \    /\\  \/.    ||:     \/  
      __/  \\  |: \.        |(|  _  \\  
     /" \   :) |.  \    /:  ||: |_)  :) 
    (_______/  |___|\__/|___|(_______/  
                                                                                                                                                                           
    Sneakerheads Mystery Box. All Rights Reserved 2022
    Developed by ATOMICON.PRO ([email protected])
*/

import "./ISneakerHeads.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error TokenIdError();
error ClaimingClosedError();
error RevealingClosedError();
error AlreadyRewardedError(uint256 _sneakerheadTokenId);
error DoesNotOwnSneakerheadError(uint256 _sneakerheadTokenId);
error SneakerheadLevelNotHighEnoughError(uint256 _sneakerheadTokenId);

contract SneakerheadsMysteryBox is ERC1155, Ownable, ERC1155Supply, ReentrancyGuard {

    /// @dev Emmited when an account reveals (burns) their mystery boxes.
    event Revealed(address indexed account, uint256 amount);

    string private boxTokenUri = "ipfs//QmYeCZwK8jrh6U82eNKHUxDm5p3TrWpsLCTYfkd9UTffRG";
    
    /// @notice Minimal staking level of the sneakerhed, required to claim a box.
    uint8 public minSneakerheadLevel = 1;
    /// @notice Deadline to claim a box.
    uint32 public claimTimeLimit = 1661817600;
    /// @notice Date and time after which a box can be revealed.
    uint32 public revealTimeStart = 1664064000;

    ISneakerHeads private _sneakerheadsContract;
    bool private _airdropHasHappened = false;
    mapping(uint256=>bool) private _isRewarded;
    
    constructor(ISneakerHeads sneakerheadsContract) ERC1155("") {
        _sneakerheadsContract = sneakerheadsContract;
    }

    /// @notice Airdrop boxes to the owners of sneakerheads tokens that have reached level 1 or higher in staking.
    function airdrop(uint256[] memory sneakerheadTokenIds)
        external
        onlyOwner
    {
        for(uint64 i = 0; i < sneakerheadTokenIds.length; i++) {
            uint256 sneakerheadTokenId = sneakerheadTokenIds[i];
            address owner = _sneakerheadsContract.ownerOf(sneakerheadTokenId);

            if(isTokenRewarded(sneakerheadTokenId)) revert AlreadyRewardedError(sneakerheadTokenId);
            if(!_sneakerheadIsHighEnoughLevel(sneakerheadTokenId)) revert SneakerheadLevelNotHighEnoughError(sneakerheadTokenId);

            _mint(owner, 1, 1, "");
            _isRewarded[sneakerheadTokenId] = true;
        }

        _airdropHasHappened = true;
    }

    /// @notice Claim a box after reaching level 1 in staking.
    function claim(uint256 sneakerheadTokenId)
        external
        nonReentrant
    {
        if(isTokenRewarded(sneakerheadTokenId)) revert AlreadyRewardedError(sneakerheadTokenId);
        if(!isClaimOpen()) revert ClaimingClosedError();       

        if(!_ownsSneakerhead(sneakerheadTokenId)) revert DoesNotOwnSneakerheadError(sneakerheadTokenId);
        if(!_sneakerheadIsHighEnoughLevel(sneakerheadTokenId)) revert SneakerheadLevelNotHighEnoughError(sneakerheadTokenId);

        _isRewarded[sneakerheadTokenId] = true;
        _mint(msg.sender, 1, 1, "");
    }
    
    /// @notice Burn a box to get a reward.
    function reveal(uint256 ammount) 
        public 
        nonReentrant 
    {
        if(!isRevealOpen()) revert RevealingClosedError();

        _burn(msg.sender, 1, ammount);
        emit Revealed(msg.sender, ammount);
    }

    function isTokenRewarded(uint256 sneakerheadTokenId) public view returns (bool) {
        return _isRewarded[sneakerheadTokenId];
    }

    function isClaimOpen() public view returns (bool) {
        return _airdropHasHappened && block.timestamp < claimTimeLimit;
    }

    function isRevealOpen() public view returns (bool) {
        return block.timestamp >= revealTimeStart;
    }

    function _ownsSneakerhead(uint256 sneakerheadTokenId) private view returns (bool) {
        return _sneakerheadsContract.ownerOf(sneakerheadTokenId) == msg.sender;
    }

    function _sneakerheadIsHighEnoughLevel(uint256 sneakerheadTokenId) private view returns (bool) {
        return _sneakerheadsContract.stockingLevel(sneakerheadTokenId) >= minSneakerheadLevel;
    }

    /// @notice Change URI with metadata of the box
    function setUri(string memory newUri) public onlyOwner {
        boxTokenUri = newUri;
    }

    /// @notice Change minimal staking level of the sneakerhed, required to claim a box.
    function setMinSneakerheadLevel(uint8 level) public onlyOwner {
        minSneakerheadLevel = level;
    }

    /// @notice Change deadline to claim a box.
    function setClaimTimeLimit(uint32 unixtime) public onlyOwner {
        claimTimeLimit = unixtime;
    }

    /// @notice Change date and time after which a box can be revealed.
    function setRevealTimeStart(uint32 unixtime) public onlyOwner {
        revealTimeStart = unixtime;
    }

    /// @notice URI with metadata of the box
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        if(tokenId != 1) revert TokenIdError();
        return boxTokenUri;
    }

    /// @notice URI with contract metadata for OpenSea
    function contractURI() public pure returns (string memory) {
        return "ipfs://QmXEkDRVWbsMEiJmnk32M2w6G3AWbrjHntn6P2vyfkqxUB";
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}