// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ICryptoFoxesOriginsV2.sol";
import "./interfaces/ICryptoFoxesStakingV2.sol";
import "./interfaces/ICryptoFoxesCalculationV2.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./CryptoFoxesUtility.sol";

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

contract CryptoFoxesStakingV2 is Ownable, CryptoFoxesUtility, ICryptoFoxesStakingV2 {

    uint32 constant HASH_SIGN_STAKING_V2 = 9248467;
    uint8 constant MIN_SLOT = 9;
    uint8 constant MAX_SLOT = 20;
    uint16 constant NULL = 65535;

    mapping(uint16 => Staking) public staked;
    mapping(uint16 => Origin) public origins;
    mapping(uint256 => bool) private signatures;
    mapping(address => uint16[]) public walletOwner;
    mapping(uint16 => uint16) private walletOwnerTokenIndex;

    address private signAddress;

    IERC721 public cryptoFoxes;
    ICryptoFoxesOriginsV2 public cryptoFoxesOrigin;
    ICryptoFoxesCalculationV2 public calculationContract;

    constructor( address _cryptoFoxesOrigin, address _cryptoFoxesContract, address _signAddress) {
        cryptoFoxesOrigin = ICryptoFoxesOriginsV2(_cryptoFoxesOrigin);
        cryptoFoxes = IERC721(_cryptoFoxesContract);
        signAddress = _signAddress;
    }

    event EventStack(uint16 _tokenId, uint16 _tokenIdOrigin, address _owner);
    event EventUnstack(uint16 _tokenId, address _owner);
    event EventClaim(uint16 _tokenId, address _owner);
    event EventMove(uint16 _tokenId, uint16 _tokenIdOriginTo, address _owner);

    //////////////////////////////////////////////////
    //      STAKING                                 //
    //////////////////////////////////////////////////

    function stack(uint16[] memory _tokenIds, uint16 _tokenIdOrigin) public {
        require(!disablePublicFunctions, "Function disabled");
        _stack(_msgSender(), _tokenIds, _tokenIdOrigin);
    }
    function stackByContract(address _wallet, uint16[] memory _tokenIds, uint16 _tokenIdOrigin) public isFoxContract{
        _stack(_wallet, _tokenIds, _tokenIdOrigin);
    }
    function _stack(address _wallet, uint16[] memory _tokenIds, uint16 _tokenIdOrigin) private {

        require(cryptoFoxesOrigin.ownerOf(_tokenIdOrigin) != address(0), "CryptoFoxesStakingV2:stack origin not minted");
        require(_tokenIdOrigin >= 1 && _tokenIdOrigin <= 1000, "CryptoFoxesStakingV2:stack token out of range");

        if(origins[_tokenIdOrigin].maxSlots == 0){
            origins[_tokenIdOrigin].maxSlots = MIN_SLOT;
        }

        require(origins[_tokenIdOrigin].stacked.length + _tokenIds.length <= origins[_tokenIdOrigin].maxSlots, "CryptoFoxesStakingV2:stack no slots");

        for(uint16 i = 0; i < _tokenIds.length; i++){

            require(cryptoFoxes.ownerOf(_tokenIds[i]) == _wallet, "CryptoFoxesStakingV2:stack Not owner");

            staked[_tokenIds[i]].tokenId = _tokenIds[i];
            staked[_tokenIds[i]].owner = _wallet;
            staked[_tokenIds[i]].timestampV2 = uint64(block.timestamp);

            _stackAction(_tokenIds[i],_tokenIdOrigin);

            cryptoFoxes.transferFrom(_wallet, address(this), _tokenIds[i]);

            walletOwnerTokenIndex[_tokenIds[i]] = uint16(walletOwner[_wallet].length);
            walletOwner[_wallet].push(_tokenIds[i]);

            emit EventStack(_tokenIds[i], _tokenIdOrigin, _wallet);
        }
    }

    function _stackAction(uint16 _tokenId, uint16 _tokenIdOrigin) private{
        staked[_tokenId].origin = _tokenIdOrigin;
        staked[_tokenId].slotIndex = uint8(origins[_tokenIdOrigin].stacked.length);
        origins[_tokenIdOrigin].stacked.push(_tokenId);
    }

    function unstack(uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public {
        require(!disablePublicFunctions, "Function disabled");
        _unstack(_msgSender(), _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function unstackByContract(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public isFoxContract{
        _unstack(_wallet, _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function _unstack(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) private {

        _claimRewardsV2(_wallet, _tokenIds, _bonusSteak, _signatureId, _signature);

        for(uint16 i = 0; i < _tokenIds.length; i++){

            require(isStaked(_tokenIds[i]) && staked[_tokenIds[i]].owner == _wallet, "CryptoFoxesStakingV2:unstack Not owner");

            uint16 tokenIdOrigin = getOriginByV2(_tokenIds[i]);
            _unstackAction(_tokenIds[i], tokenIdOrigin);

            staked[_tokenIds[i]].tokenId = NULL;

            cryptoFoxes.transferFrom(address(this), _wallet, _tokenIds[i]);

            uint16 index = walletOwnerTokenIndex[_tokenIds[i]];
            uint16 last = uint16(walletOwner[_wallet].length - 1);

            if(index != last){
                walletOwner[_wallet][index] = walletOwner[_wallet][last];
                walletOwnerTokenIndex[ walletOwner[_wallet][last] ] = index;
            }
            walletOwner[_wallet].pop();

            emit EventUnstack(_tokenIds[i], _wallet);
        }
    }

    function _unstackAction(uint16 _tokenId, uint16 _tokenIdOrigin) private{
        uint8 slotIndex = staked[_tokenId].slotIndex;
        uint8 lastSlot = uint8(origins[_tokenIdOrigin].stacked.length - 1);

        if(slotIndex != lastSlot){
            origins[_tokenIdOrigin].stacked[slotIndex] = origins[_tokenIdOrigin].stacked[lastSlot];
            staked[ origins[_tokenIdOrigin].stacked[lastSlot] ].slotIndex = slotIndex;
        }

        origins[_tokenIdOrigin].stacked.pop();
    }

    function claimSignature(address _wallet, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public pure returns(address){
        return ECDSA.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encode(_wallet, _bonusSteak, _signatureId, HASH_SIGN_STAKING_V2)))), _signature);
    }

    function moveStack(uint16 _tokenId, uint16 _tokenIdOriginTo) public {
        require(!disablePublicFunctions, "Function disabled");
        _moveStack(_msgSender(), _tokenId, _tokenIdOriginTo);
    }
    function moveStackByContract(address _wallet, uint16 _tokenId, uint16 _tokenIdOriginTo) public isFoxContract {
        _moveStack(_wallet, _tokenId, _tokenIdOriginTo);
    }
    function _moveStack(address _wallet, uint16 _tokenId, uint16 _tokenIdOriginTo) private {

        require(isStaked(_tokenId), "CryptoFoxesStakingV2:moveStack Not owner");
        uint16 tokenIdOrigin = getOriginByV2(_tokenId);
        require(tokenIdOrigin != _tokenIdOriginTo, "CryptoFoxesStakingV2:moveStack not moving tokenId");
        require(cryptoFoxesOrigin.ownerOf(tokenIdOrigin) == _wallet, "CryptoFoxesStakingV2:moveStack origin not owner");
        require(cryptoFoxesOrigin.ownerOf(_tokenIdOriginTo) != address(0), "CryptoFoxesStakingV2:moveStack originTo not minted");
        require(_tokenIdOriginTo >= 1 && _tokenIdOriginTo <= 1000, "CryptoFoxesStakingV2:moveStack tokenTo out of range");

        if(origins[_tokenIdOriginTo].maxSlots == 0){
            origins[_tokenIdOriginTo].maxSlots = MIN_SLOT;
        }

        require(origins[_tokenIdOriginTo].stacked.length < origins[_tokenIdOriginTo].maxSlots, "CryptoFoxesStakingV2:moveStack no slots");

        _unstackAction(_tokenId, tokenIdOrigin);
        _stackAction(_tokenId,_tokenIdOriginTo);

        calculationContract.claimMoveRewardsOrigin(address(this), _tokenId, _wallet);

        staked[_tokenId].timestampV2 = uint64(block.timestamp);

        emit EventMove(_tokenId, _tokenIdOriginTo, _wallet);
    }

    //////////////////////////////////////////////////
    //      SLOTS                                   //
    //////////////////////////////////////////////////

    function unlockSlot(uint16 _tokenIdOrigin, uint8 _count) public override isFoxContractOrOwner {
        if(origins[_tokenIdOrigin].maxSlots == 0){
            origins[_tokenIdOrigin].maxSlots = MIN_SLOT;
        }
        require(origins[_tokenIdOrigin].maxSlots + _count <= MAX_SLOT, "CryptoFoxesStakingV2:unlockSlot Max slot limit");
        origins[_tokenIdOrigin].maxSlots += _count;
    }

    //////////////////////////////////////////////////
    //      REWARDS                                 //
    //////////////////////////////////////////////////

    function calculateRewardsV2(uint16[] memory _tokenIds, uint256 _currentTimestamp) public view returns (uint256) {
        return calculationContract.calculationRewardsV2(address(this), _tokenIds, _currentTimestamp);
    }

    function claimRewardsV2(uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public {
        require(!disablePublicFunctions, "Function disabled");
        _claimRewardsV2(_msgSender(), _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function claimRewardsV2ByContract(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) public isFoxContract {
        _claimRewardsV2(_wallet, _tokenIds, _bonusSteak, _signatureId, _signature);
    }
    function _claimRewardsV2(address _wallet, uint16[] memory _tokenIds, uint256 _bonusSteak, uint256 _signatureId, bytes memory _signature) private {

        require(_tokenIds.length > 0 && !isPaused(), "Tokens empty");

        if(_bonusSteak > 0){
            require(signatures[_signatureId] == false, "CryptoFoxesStakingV2:claimRewardsV2 signature used");
            signatures[_signatureId] = true;
            require(claimSignature(_wallet, _bonusSteak, _signatureId, _signature) == signAddress, "CryptoFoxesStakingV2:claimRewardsV2 signature fail"); // 6k
            _addRewards(_wallet, _bonusSteak);
        }

        for(uint16 i = 0; i < _tokenIds.length; i++){
            require(isStaked(_tokenIds[i]) && staked[_tokenIds[i]].owner == _wallet, "Bad owner");

            for (uint16 j = 0; j < i; j++) {
                require(_tokenIds[j] != _tokenIds[i], "Duplicate id");
            }
        }

        calculationContract.claimRewardsV2(address(this), _tokenIds, _wallet);

        for(uint16 i = 0; i < _tokenIds.length; i++){
            staked[_tokenIds[i]].timestampV2 = uint64(block.timestamp);

            emit EventClaim(_tokenIds[i], _wallet);
        }

    }

    //////////////////////////////////////////////////
    //      GETTERS                                 //
    //////////////////////////////////////////////////

    function getFoxesV2(uint16 _tokenId) public view override returns(Staking memory){
        return staked[_tokenId];
    }
    function getOriginByV2(uint16 _tokenId) public view override returns(uint16){
        return staked[_tokenId].origin;
    }
    function getStakingTokenV2(uint16 _tokenId) public override view returns(uint256){
        return uint256(staked[_tokenId].timestampV2);
    }
    function totalSupply() public view returns(uint16){
        uint16 totalStaked = 0;
        for(uint16 i = 1; i <= 1000; i++){
            totalStaked += uint16(origins[i].stacked.length);
        }
        return totalStaked;
    }
    function getOriginMaxSlot(uint16 _tokenIdOrigin) public view override returns(uint8){
        return origins[_tokenIdOrigin].maxSlots;
    }
    function getV2ByOrigin(uint16 _tokenIdOrigin) public override view returns(Staking[] memory){
        Staking[] memory tokenIds = new Staking[](origins[_tokenIdOrigin].stacked.length);
        for(uint16 i = 0; i < origins[_tokenIdOrigin].stacked.length; i++){
            tokenIds[i] = staked[ origins[_tokenIdOrigin].stacked[i] ];
        }
        return tokenIds;
    }
    function walletOfOwner(address _wallet) public view returns(Staking[] memory){
        Staking[] memory tokenIds = new Staking[](walletOwner[_wallet].length);
        for(uint16 i = 0; i < walletOwner[_wallet].length; i++){
            tokenIds[i] = staked[ walletOwner[_wallet][i] ];
        }
        return tokenIds;
    }

    //////////////////////////////////////////////////
    //      SETTERS                                 //
    //////////////////////////////////////////////////

    function setCryptoFoxes(address _contract) public onlyOwner{
        if(address(cryptoFoxes) != address(0)) {
            setAllowedContract(address(cryptoFoxes), false);
        }
        cryptoFoxes = IERC721(_contract);
        setAllowedContract(_contract, true);

    }
    function setCryptoFoxesOrigin(address _contract) public onlyOwner{
        if(address(cryptoFoxesOrigin) != address(0)) {
            setAllowedContract(address(cryptoFoxesOrigin), false);
        }
        cryptoFoxesOrigin = ICryptoFoxesOriginsV2(_contract);
        setAllowedContract(_contract, true);

    }
    function setCalculationContract(address _contract) public isFoxContractOrOwner {
        if(address(calculationContract) != address(0)) {
            setAllowedContract(address(calculationContract), false);
        }

        calculationContract = ICryptoFoxesCalculationV2(_contract);
        setAllowedContract(_contract, true);
    }
    function setSignAddress(address _signAddress) external onlyOwner{
        signAddress = _signAddress;
    }
    function updateTimestampV2(uint16 _tokenId, uint64 _timestamp) public isFoxContract{
        staked[_tokenId].timestampV2 = _timestamp;
    }

    //////////////////////////////////////////////////
    //      TESTERS                                 //
    //////////////////////////////////////////////////

    function isStaked(uint16 _tokenId) public view returns(bool){
        return staked[_tokenId].tokenId != NULL && staked[_tokenId].timestampV2 != 0;
    }

    //////////////////////////////////////////////////
    //      OTHER                                   //
    //////////////////////////////////////////////////

    function _currentTime(uint256 _currentTimestamp) public override(ICryptoFoxesStakingV2, CryptoFoxesUtility) view returns (uint256) {
        return super._currentTime(_currentTimestamp);
    }
}