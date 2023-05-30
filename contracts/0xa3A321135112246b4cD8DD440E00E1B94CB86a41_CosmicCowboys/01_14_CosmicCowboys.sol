// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721.sol";
import "./WithdrawFairlyCowboys.sol";

contract CosmicCowboys is ERC721, Ownable, WithdrawFairlyCowboys {

    uint256 public constant MAX_SUPPLY = 6969;
    uint256 public constant MAX_PER_TX = 20;
    uint256 public constant START_AT = 1;

    mapping (uint256 => bool) private cosmicCowgirlClaimed;
    bool public paused = false;
    uint256 public claimTracker = 0;
    uint256 public burnedTracker = 0;

    string public baseTokenURI;

    event ClaimCosmicCowboy(uint256 indexed _tokenId);

    IERC721 public cosmicCowGirls;
    constructor(string memory baseURI, address _cosmicCowGirls) ERC721("CosmicCowboys", "CCB") {
        setBaseURI(baseURI);
        setCosmicCowgirls(_cosmicCowGirls);
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier claimIsOpen {
        require(!paused, "Claim paused");
        _;
    }

    //******************************************************//
    //                     Claim                            //
    //******************************************************//
    function claim(uint256[] memory _tokensId) public claimIsOpen {
        require(_tokensId.length <= MAX_PER_TX, "Exceeds number");

        for (uint256 i = 0; i < _tokensId.length; i++) {

            require(canClaim( _tokensId[i] ) && cosmicCowGirls.ownerOf( _tokensId[i] ) == _msgSender(), "Bad owner!");
            cosmicCowgirlClaimed[_tokensId[i]] = true;

            _mintToken(_msgSender(), _tokensId[i]);

        }
    }
    function canClaim(uint256 _tokenId) public view returns(bool) {
        return cosmicCowgirlClaimed[_tokenId] == false;
    }
    function _mintToken(address _wallet, uint256 _tokenId) private {
        claimTracker += 1;
        _safeMint(_wallet, _tokenId);
        emit ClaimCosmicCowboy(_tokenId);
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function totalSupply() public view returns(uint256){
        return claimTracker - burnedTracker;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        if(tokenCount == 0){
            return tokensId;
        }

        uint256 key = 0;
        for (uint256 i = START_AT; i <= MAX_SUPPLY; i++) {
            if(rawOwnerOf(i) == _owner){
                tokensId[key] = i;
                key++;
                if(key == tokenCount){break;}
            }
        }
        return tokensId;
    }
    
    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }
    function setPause(bool _toggle) public onlyOwner {
        paused = _toggle;
    }
    function setCosmicCowgirls(address _cosmicCowGirls) public onlyOwner {
        cosmicCowGirls = IERC721(_cosmicCowGirls);
    }

    //******************************************************//
    //                      Burn                            //
    //******************************************************//
    function burn(uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not owner nor approved");
        burnedTracker += 1;
        _burn(_tokenId);
    }
}