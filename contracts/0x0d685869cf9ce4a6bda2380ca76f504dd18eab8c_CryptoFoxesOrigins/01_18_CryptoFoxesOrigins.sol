// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ICryptoFoxesCalculationOrigin.sol";
import "./CryptoFoxesUtility.sol";
import "./ICryptoFoxesOrigins.sol";

// @author: miinded.com

/////////////////////////////////////////////////////////////////////////////////////                                                                                                                                                          
//                                                                                 //
//                                                                                 //
//                    ((((((((.                (((((                               //
//                    @@@@@@@@.                @@@@@                               //
//                    @@@&&&%%@@@              @@@&&@@@                            //
//                    @@@%%%@@#((@@@        @@@&&&&&%%%@@@                         //
//                    @@@(((%%,..(((@@&     @@@&&&%%///@@@                         //
//                 %@@(((@@@..   [email protected]@&     @@@%%%/////(((@@%                      //
//                 %@@///@@&        ///@@@@@%%%%%%((//////@@%                      //
//                 (%%///@@&        @@@/////(((@@@%%%%%///@@%                      //
//                 (%%///@@&     %%%(((///////////((@@@(((%%#                      //
//                 (%%///...  #%%/////////////////////////%%#                      //
//                 %@@///@@@@@#((/////////////////////////@@%                      //
//                 %@@///%%%%%(((////////((((((/////((((((%%#//                    //
//                 %@@///(((/////////////((((((/////((((((((#@@                    //
//               @@#((//////////////////////////////////////(%%                    //
//               @@#((//////////////&&&&&&&&&&&////////&&&&&&%%                    //
//               @@(/////////////&&&     (((   ////////(((  ,&&                    //
//            @@@((///////////(((&&&     ###   ///(((((###  ,&&%%%                 //
//            @@@/////......     (((///////////((#&&&&&&&&..,((%%%                 //
//            @@@((.                ..,//,.....     &&&     .//@@@                 //
//               @@#((...                      &&&&&...&&&     @@@                 //
//    @@@@@      @@#((                                       [email protected]@@                 //
// @@@..(%%        %@@%%%%%%.....                         ..*%%                    //
// (((../((***     /((///////////*************************/////                    //
//      ...%%%              @@&%%%%%%%%%%%%%%%%%%%%%@@@@@@%%#                      //
//         ...%%%        &&%##(((.................**@@@                            //
//            [email protected]@,     %%%/////...              ..(((@@@                         //
// ...        ///((&@@@@@////////%%%             .%%(((@@@              Miinded    //
// ...     ////////(((@@@/////(((%%%             .%%((((((%%#                      //
/////////////////////////////////////////////////////////////////////////////////////

contract CryptoFoxesOrigins is ERC721, Ownable, ICryptoFoxesOrigins, CryptoFoxesUtility {
    using SafeMath for uint256;

    IERC1155 public constant OPENSEA_STORE = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);
    uint256 public constant MAX_ELEMENTS = 1000;
    uint256 internal _foxIdTracker;

    struct ExtraMint{
        uint256 startId;
        uint256 endId;
        uint256 trackerId;
        uint256 isBurnable;
        uint256 limitTime;
    }

    ExtraMint[] public extraMint;
    mapping(uint256 => uint256) public stackingOrigins;
    mapping(address => mapping(uint256 => uint256)) public ownerOrigins;
    mapping(uint256 => uint256) private ownerOriginsIndex;

    string public baseTokenURI;

    ICryptoFoxesCalculationOrigin public calculationContract;
    constructor(string memory baseURI) ERC721("CryptoFoxesOrigins", "CFXSO") {
        setBaseURI(baseURI);
        setAllowedContract(address(this), true);
    }

    modifier extraMintTimeLimit(uint256 _extraMintId){
        require(extraMint[_extraMintId].limitTime == 0 || block.timestamp < extraMint[_extraMintId].limitTime, "Time limit");
        _;
    }

    modifier extraMintRange(uint256 _extraMintId,uint256 _tokenId){
        require(_tokenId >= extraMint[_extraMintId].startId && _tokenId <= extraMint[_extraMintId].endId, "Not in range");
        _;
    }

    function totalSupply() public view returns (uint256) {
        uint256 total = _foxIdTracker;
        for(uint256 i; i < extraMint.length; i++){
            total = total.add(extraMint[i].trackerId);
        }
        return total;
    }

    function totalMintFox() public view returns (uint256) {
        return _foxIdTracker;
    }

    function getUnmintedExtraToken(uint256 _extraMintId) public view extraMintTimeLimit(_extraMintId) returns(uint256[] memory) {
        uint256[] memory result = new uint256[](extraMint[_extraMintId].endId.sub(extraMint[_extraMintId].startId).sub(extraMint[_extraMintId].trackerId).add(1));
        uint256 _index = 0;
        for(uint256 i = extraMint[_extraMintId].startId; i <= extraMint[_extraMintId].endId; i++){
            if(!_exists(i)){
                result[_index] = i;
                _index += 1;
            }
        }
        return result;
    }

    function mintExtraToken(uint256 _extraMintId, address _to, uint256 _id) public isFoxContract extraMintRange(_extraMintId, _id) extraMintTimeLimit(_extraMintId) {
        require(extraMint[_extraMintId].trackerId <= extraMint[_extraMintId].endId.sub(extraMint[_extraMintId].startId) && !isPaused(), "Max supply or paused");
         
        extraMint[_extraMintId].trackerId += 1;

        _safeMint(_to, _id);
    }

    function burnExtraToken(uint256 _extraMintId,uint256 _tokenId) public isFoxContract extraMintRange(_extraMintId, _tokenId) {
        require(extraMint[_extraMintId].isBurnable > 0 && !isPaused() && _tokenId > MAX_ELEMENTS, "Not burnable or paused or > 1000");

        require(_isApprovedOrOwner(_msgSender(), _tokenId));

        extraMint[_extraMintId].trackerId -= 1;

        _burn(_tokenId);
    }

    function setExtraMintData(ExtraMint memory _extraMint) public isFoxContractOrOwner {
        extraMint.push(_extraMint);
    }

    function editExtraMintData(uint256 _extraMintId, ExtraMint memory _extraMint) public isFoxContractOrOwner {
        extraMint[_extraMintId] = _extraMint;
    }

    function _stack(uint256 _tokenId) private {
        stackingOrigins[_tokenId] = block.timestamp;
    }
    
    function migrateOrigins(uint256 _tokenId) public virtual{
        uint256 total = totalMintFox();
        require(total + 1 <= MAX_ELEMENTS && isValidFox(_tokenId), "Max limit or invalid");
        uint256 originId = returnCorrectId(_tokenId);
        _foxIdTracker += 1;
        _safeMint(_msgSender(), originId);

        OPENSEA_STORE.safeTransferFrom(_msgSender(), 0x000000000000000000000000000000000000dEaD, _tokenId, 1, "");

        _stack(originId);
        _addRewards(_msgSender(), 30 * 10**18);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addOwnerOrigins(tokenId, to);
        } else if (from != to) {
            _deleteOwnerOrigins(tokenId, from);
        }
        
        if (to == address(0)) {
            _deleteOwnerOrigins(tokenId, from);

        } else if (to != from && from != address(0)) {
            _addOwnerOrigins(tokenId, to);
        }

        if(from != address(0) && tokenId <= MAX_ELEMENTS){
            uint256[] memory array = new uint256[](1);
            array[0] = tokenId;
            _addRewards(from, calculateRewardsOrigins(array, block.timestamp));
            _stack(tokenId);
        }
    }

    function _addOwnerOrigins(uint256 _tokenId, address _to) private{

        uint256 length = balanceOf(_to);

        ownerOrigins[_to][length] = _tokenId;
        ownerOriginsIndex[_tokenId] = length;
    }

    function _deleteOwnerOrigins(uint256 _tokenId, address _to) private{

        uint256 length = balanceOf(_to);
        uint256 index = ownerOriginsIndex[_tokenId];
        uint256 lastTokenId = ownerOrigins[_to][length - 1];

        if(_tokenId != lastTokenId){
            ownerOrigins[_to][index] = lastTokenId;
            ownerOriginsIndex[lastTokenId] = index;
        }

        delete ownerOrigins[_to][_tokenId];
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 length = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++){
            tokenIds[i] = ownerOrigins[_owner][i];
        }
        return tokenIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function isValidFox(uint256 _id) public pure virtual returns (bool) {
        if (_id >> 96 != 0x0000000000000000000000001b6284B63ad8e0b0E254500869896153A2260D1c) return false;
        if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1) return false;
        uint256 id = returnCorrectId(_id);
        if (id < 1 && id > 1000) return false;
        return true;
    }

    function returnCorrectId(uint256 _id) public pure virtual returns (uint256) {

        _id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
        if (_id == 200) return _id - 52;
        if (_id == 205) return _id - 56;
        if (_id == 214) return _id - 67;
        if (_id == 80) return _id - 79;
        if (_id == 232) return _id - 86;
        if (_id == 244) return _id - 110;
        if (_id == 245) return _id - 129;
        if (_id == 247) return _id - 140;
        if (_id == 246) return _id - 144;
        if (_id < 250) return _id - 98;
        if (_id < 400) return _id - 99;
        if (_id < 570) return _id - 119;
        if (_id < 771) return _id - 120;
        if (_id < 840) return _id - 123;
        if (_id < 1125) return _id - 124;
        return _id;
    }

    function setCalculationContract(address _contract) public isFoxContractOrOwner {
        calculationContract = ICryptoFoxesCalculationOrigin(_contract);
        setAllowedContract(_contract, true);
    }

    function calculateRewardsOrigins(uint256[] memory _tokenIds, uint256 _currentTimestamp) public view returns (uint256) {
        return calculationContract.calculationRewards(address(this), _tokenIds, _currentTimestamp);
    }

    function claimRewardsOrigins(uint256[] memory _tokenIds) public {

        require(_tokenIds.length > 0 && !isPaused(), "Tokens empty");

        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(ownerOf(_tokenIds[i]) == _msgSender(), "Bad owner");
        }
        calculationContract.claimRewards(address(this), _tokenIds, _msgSender());
        for(uint256 i = 0; i < _tokenIds.length; i++){
            _stack(_tokenIds[i]);
        }
    }

    function getExtraMintCollection() public view returns(uint256) {
        return extraMint.length;
    }

    function getStackingToken(uint256 _tokenId) public override view returns(uint256) {
        return stackingOrigins[_tokenId];
    }

    function _currentTime(uint256 _currentTimestamp) public override(ICryptoFoxesOrigins, CryptoFoxesUtility) view returns (uint256) {
        return super._currentTime(_currentTimestamp);
    }
}