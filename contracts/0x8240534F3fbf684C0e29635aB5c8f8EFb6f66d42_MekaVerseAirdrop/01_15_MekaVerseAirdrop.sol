// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./MekaVerseInterface.sol";
import "./MekaVerseAllowed.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// @author: miinded.com

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                                                                    ///
//                                              .--==-:.                              ///
//                                 ..-=++=:     -==****.                              ///
//                               +#%@@@@#+-:.  -=+****-                               ///
//                               +#@@%##*+-::--=+****:                                ///
//                 .::           =#%@%##*=-:--+****+.                                 ///
//                 .:::.         -***++-::--+*****:                                   ///
//                  .::::.      .==*+=--=+****##*=-:.                                 ///
//                   ..:::::::.:*-+#%%%##***#%%%#%##*+=:.                             ///
//                   ..:--==++++++#%%%%###%@%@%%%%###++=-..:.                         ///
//                      .:-=++****#%%#######%%%%%%%%%%%%%#+*+-.                       ///
//                          :=*****###%%@@@@@@@@@@@@@%@@@%%%%*=.                      ///
//                        :-==*#%@@@@@@@@@@@@@@@@@@%###%@@@##**=                      ///
//                       ::=#@@@@@@@@@@@@@@@@@@@@@@####%@@%#+===                      ///
//                      .-%@@@@@@@@%%%##*#@@@@@@@@@#####@@%%@*=++-.                   ///
//                      :*%%@@@@@@@*=#%%****###%%%#**##%@@%%@%%%###*:                 ///
//                      .#*%%@@%+:.:=*%%#+*##*=-*#**###%@@%@@@%@%###*                 ///
//                       +*##%@-  ..===+++*+=++*######%%@%%@@@@@@@%#*                 ///
//                      .+*+**@*:.=+++*++*#+-#%@####%%%%%%@%%@@@@%#=.                 ///
//                    :--*+*##@@@%%%@####%%%:#%@%####@@%%@%#%%%%*                     ///
//                   -+*+*++##%@@@@@@%++#%%@*%%@#%%#%@@%@@%####%=                     ///
//                   -#####=+%%@@@@@@@###%%%@%*#%%@@%@@%@@@%###%=                     ///
//                    ###*#++#%@@@@@@@%%%%%%@@@%%@%@@@@%%@@@%###=                     ///
//                    :+++#**#%%@@@@@@%%%%%@@@@@@@@@@@@@@%@@@%#*-                     ///
//                       -%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%#-                     ///
//                        %@@#%@@@@@@@@@@%%%%%@@@@@@@@@@@@@@@@@#-            :-::==-::///
//                        [email protected]@*@@@@@@@@@@%####%%@@@%%%@@@@@@%#**###+.  ..-: .=++*+*###*///
//                            [email protected]@@@@@%%@%####%%@@%%%##%%%%#*###%#%#+=++#%%**+++###***+///
//                             %@@@++*#%*=++**#######%###########%#+++=#@@%#%*+++**#%%///
//                              -+*=+=-::::::--==+*#**+++=-++++**#*+++=*@@@@%%%%##*+++///
//                          :*=-==-:.   .....:::--==++++--#%****#%#++*++%@@@%@@@@@@%%%///
//                        --===-...:::----=============++%@@%%###%%*+*++#@@@@%@@@@@@@@///
//                 .::-*%*--=-.::------========++++======+*%%%%%%%@#+*#**%@@@@%@@@@@@@///
//       :.:-=+%%---:*%*+==-::-----=====+=++++++++++*++===+*%%%#***++#%#*#%@@@@@@@@@@@///
//    :**#%[email protected]%%==--*@#*+=::-=--=====+++*+*++++*#%#++**+++++*%%##*****@@##%@@@@@@@@@@@///
/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

contract MekaVerseAirdrop is ERC1155, Ownable, MekaVerseAllowed {

    string public baseTokenURI;
    MekaVerseInterface public mekaverse;

    struct ClaimCollection {
        uint256 tokenId;
        uint256 start;
        uint256 end;
        bool paused;
        bool canExternal;
        uint256 maxPerWallet;
        uint256 maxPerTx;
        uint256 maxSupply;
    }

    mapping(uint256 => ClaimCollection) public collections;
    mapping(uint256 => uint256) public currentSupply;

    uint256 public collectionIndex;

    mapping(uint256 => mapping(uint256 => bool)) public tokenIsUsed;
    mapping(uint256 => mapping(address => uint256)) public balanceCollection;

    bool public pauseAllCollection = false;

    event CreateMekaVerseHold(uint256 indexed collectionId, uint256 indexed count);

    constructor(string memory _baseURI, address _mekaverse) ERC1155(_baseURI) {
        setURI(_baseURI);
        mekaverse = MekaVerseInterface(_mekaverse);
    }

    //******************************************************//
    //                     Modifier                         //
    //******************************************************//
    modifier collectionIsOpen(uint256 _collectionId) {
        require(!collectionIsPaused(_collectionId) && !pauseAllCollection, "Claim is paused");
        require(collections[_collectionId].tokenId > 0, "Collection does not exist");
        require(collectionIsClaimable(_collectionId), "Claim is closed");
        _;
    }

    //******************************************************//
    //                Collection logic                      //
    //******************************************************//
    function addCollection(ClaimCollection memory _collection) external onlyOwner {
        collectionIndex += 1;
        collections[collectionIndex] = _collection;
    }

    function editCollection(uint256 _collectionId, ClaimCollection memory _collection) external onlyOwner {
        require(_collectionId <= collectionIndex, "Collection does not exist");
        collections[_collectionId] = _collection;
    }

    function setPauseCollection(uint256 _collectionId, bool _paused) external onlyOwner {
        require(_collectionId <= collectionIndex, "Collection does not exist");
        collections[_collectionId].paused = _paused;
    }

    function collectionIsClaimable(uint256 _collectionIndex) public view returns (bool){
        return block.timestamp >= collections[_collectionIndex].start && block.timestamp <= collections[_collectionIndex].end;
    }

    function collectionIsPaused(uint256 _collectionIndex) public view returns (bool){
        return collections[_collectionIndex].paused;
    }

    function collectionClaimable() public view returns (ClaimCollection[] memory){
        ClaimCollection[] memory claimable = new ClaimCollection[](collectionIndex + 1);
        for (uint256 i = 1; i <= collectionIndex; i++) {
            claimable[i] = collections[i];
        }
        return claimable;
    }

    //******************************************************//
    //                     Claim                            //
    //******************************************************//
    // I can claim my token for someone else if i want to (send a gift for example)
    function claim(address _to, uint256 _collectionId, uint256[] memory _tokensId) public collectionIsOpen(_collectionId) {
        require(!collections[_collectionId].canExternal, "Reserve MekaVerse Holder");

        for (uint256 i = 0; i < _tokensId.length; i++) {
            uint256 _tokenId = _tokensId[i];
            require(canClaim(_collectionId, _tokenId), "Token already used");
            require(mekaverse.ownerOf(_tokenId) == _msgSender(), "Bad owner!");
            tokenIsUsed[_collectionId][_tokenId] = true;
        }

        _mintToken(_to, collections[_collectionId].tokenId, _tokensId.length);
    }

    function canClaim(uint256 _collectionId, uint256 _tokenId) public view returns (bool) {
        return tokenIsUsed[_collectionId][_tokenId] == false;
    }

    function claimExternal(address _to, uint256 _collectionId, uint256 _count) public collectionIsOpen(_collectionId) isMekaContract(_collectionId) {
        require(_count <= collections[_collectionId].maxPerTx, "Max per tx");
        require(currentSupply[_collectionId] + _count <= collections[_collectionId].maxSupply, "Max Supply");
        require(balanceCollection[_collectionId][_to] + _count <= collections[_collectionId].maxPerWallet, "Max allowed");

        _mintToken(_to, collections[_collectionId].tokenId, _count);
    }

    function _mintToken(address _to, uint256 _collectionId, uint256 _count) private {
        _mint(_to, _collectionId, _count, "");
        balanceCollection[_collectionId][_to] += _count;
        currentSupply[_collectionId] += _count;
        emit CreateMekaVerseHold(_collectionId, _count);
    }

    //******************************************************//
    //                      Setters                         //
    //******************************************************//
    function setMekaverse(address _mekaverse) external onlyOwner {
        mekaverse = MekaVerseInterface(_mekaverse);
    }

    function setURI(string memory _baseURI) public onlyOwner {
        _setURI(_baseURI);
    }

    function setPauseAllCollection(bool _toggle) public onlyOwner {
        pauseAllCollection = _toggle;
    }

    //******************************************************//
    //                      Getters                         //
    //******************************************************//
    function totalSupply(uint256 _collectionId) public view returns (uint256) {
        return currentSupply[_collectionId];
    }
    function totalMint() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= collectionIndex; i++) {
            total += currentSupply[i];
        }
        return total;
    }
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        require(collectionIndex > 0);
        uint256[] memory tokensId = new uint256[](collectionIndex + 1);
        for (uint256 i = 1; i <= collectionIndex; i++) {
            tokensId[i] = balanceOf(_owner, i);
        }

        return tokensId;
    }
    function removeAllowedContract(address _contract) public onlyOwner {
        require(collectionIndex > 0);
        for (uint256 i = 1; i <= collectionIndex; i++) {
            allowedContracts[_contract][i] = false;
        }
    }
}