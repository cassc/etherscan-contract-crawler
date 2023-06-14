pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

///@title Frens Staking Pool Contract
///@author 0xWildhare and the FRENS team
///@dev A new instance of this contract is created everytime a user makes a new pool

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IFrensPoolShare.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/IFrensArt.sol";
import "./interfaces/IFrensOracle.sol";
import "./interfaces/IFrensStorage.sol";

contract StakingPool is IStakingPool, Ownable{
    event Stake(address depositContractAddress, address caller);
    event DepositToPool(uint amount, address depositer, uint id);

    modifier noZeroValueTxn() {
        require(msg.value > 0, "must deposit ether");
        _;
    }

    modifier maxTotDep() {
        require(
            msg.value + totalDeposits <= 32 ether,
            "total deposits cannot be more than 32 Eth"
        );
        _;
    }

    modifier mustBeAccepting() {
        require(
            currentState == PoolState.acceptingDeposits,
            "not accepting deposits"
        );
        _;
    }

    modifier correctPoolOnly(uint _id) {
        require(
            frensPoolShare.poolByIds(_id) == address(this),
            "wrong staking pool for id"
        );
        _;
    }

    enum PoolState {
        awaitingValidatorInfo,
        acceptingDeposits,
        staked,
        exited
    }
    PoolState currentState;
    
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    struct RageQuit {
        uint price;
        uint time;
        bool rageQuitting;
    }

    //maps the ID for each FrensPoolShare NFT in the pool to the deposit for that share
    mapping(uint => uint) public depositForId;
    //maps each ID to the rewards it has already claimed (used in calculating the claimable rewards)
    mapping(uint => uint) public frenPastClaim;
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    mapping(uint => bool) public locked; //transfer locked (must use ragequit)
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    mapping(uint => RageQuit) public rageQuitInfo;

    //total eth deposited to pool by users (does not include attestation or block rewards)
    uint public totalDeposits;
    //total amount of rewards claimed from pool (used in calculating the claimable rewards)
    uint public totalClaims;
    //these are the ids which have deposits in this pool
    uint[] public idsInPool;

    //this is set in the constructor and requires the validator public key and other validator info be set before deposits can be made
    //also, if the validator is locked, once set, the pool owner cnnot change the validator pubkey and other info
    bool public validatorLocked;
    //this is unused in this version of the system
    //it must be included to avoid requiring an update to FrensPoolShare when rageQuit is added
    bool public transferLocked;
    //set as true once the validator info has been set for the pool
    bool public validatorSet;

    //validator public key for pool
    bytes public pubKey;
    //validator withdrawal credentials - must be set to pool address
    bytes public withdrawal_credentials;
    //bls signature for validator
    bytes public signature;
    //deposit data root for validator
    bytes32 public deposit_data_root;

    IFrensPoolShare public frensPoolShare;
    IFrensArt public artForPool;
    IFrensStorage public frensStorage;

    /**@dev when the pool is deploied by the factory, the owner, art contract, 
    *storage contract, and if the validator is locked are all set. 
    *The pool state is set according to whether or not the validator is locked.
    */
    constructor(
        address owner_,
        bool validatorLocked_,
        IFrensStorage frensStorage_
    ) {
        frensStorage = frensStorage_;
        artForPool = IFrensArt(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensArt"))));
        frensPoolShare = IFrensPoolShare(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensPoolShare"))));
        validatorLocked = validatorLocked_;
        if (validatorLocked) {
            currentState = PoolState.awaitingValidatorInfo;
        } else {
            currentState = PoolState.acceptingDeposits;
        }
        _transferOwnership(owner_);
    }

    ///@notice This allows a user to deposit funds to the pool, and recieve an NFT representing their share
    ///@dev recieves funds and returns FrenspoolShare NFT
    function depositToPool()
        external
        payable
        noZeroValueTxn
        mustBeAccepting
        maxTotDep
    {
        uint id = frensPoolShare.totalSupply();
        depositForId[id] = msg.value;
        totalDeposits += msg.value;
        idsInPool.push(id);
        frenPastClaim[id] = 1; //this avoids future rounding errors in rewardclaims
        locked[id] = transferLocked;
        frensPoolShare.mint(msg.sender); //mint nft
        emit DepositToPool(msg.value, msg.sender, id);
    }

    ///@notice allows a user to add funds to an existing NFT ID
    ///@dev recieves funds and increases deposit for a FrensPoolShare ID
    function addToDeposit(uint _id) external payable mustBeAccepting maxTotDep correctPoolOnly(_id){
        require(frensPoolShare.exists(_id), "id does not exist"); //id must exist
        
        depositForId[_id] += msg.value;
        totalDeposits += msg.value;
    }

    ///@dev stakes 32 ETH from this pool to the deposit contract, accepts validator info
    function stake(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        //if validator info has previously been entered, check that it is the same, then stake
        if (validatorSet) {
            require(keccak256(_pubKey) == keccak256(pubKey), "pubKey mismatch");
        } else {
            //if validator info has not previously been entered, enter it, then stake
            _setPubKey(
                _pubKey,
                _withdrawal_credentials,
                _signature,
                _deposit_data_root
            );
        }
        _stake();
    }

    ///@dev stakes 32 ETH from this pool to the deposit contract. validator info must already be entered
    function stake() external onlyOwner {
        _stake();
    }

    function _stake() internal {
        require(address(this).balance >= 32 ether, "not enough eth");
        require(totalDeposits == 32 ether, "not enough deposits");
        require(currentState == PoolState.acceptingDeposits, "wrong state");
        require(validatorSet, "validator not set");
        
        address depositContractAddress = frensStorage.getAddress(keccak256(abi.encodePacked("external.contract.address", "DepositContract")));
        currentState = PoolState.staked;
        IDepositContract(depositContractAddress).deposit{value: 32 ether}(
            pubKey,
            withdrawal_credentials,
            signature,
            deposit_data_root
        );
        emit Stake(depositContractAddress, msg.sender);
    }

    ///@dev sets the validator info required when depositing to the deposit contract
    function setPubKey(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) external onlyOwner {
        _setPubKey(
            _pubKey,
            _withdrawal_credentials,
            _signature,
            _deposit_data_root
        );
    }

    function _setPubKey(
        bytes calldata _pubKey,
        bytes calldata _withdrawal_credentials,
        bytes calldata _signature,
        bytes32 _deposit_data_root
    ) internal {
        //get expected withdrawal_credentials based on contract address
        bytes memory withdrawalCredFromAddr = _toWithdrawalCred(address(this));
        //compare expected withdrawal_credentials to provided
        require(
            keccak256(_withdrawal_credentials) ==
                keccak256(withdrawalCredFromAddr),
            "withdrawal credential mismatch"
        );
        if (validatorLocked) {
            require(currentState == PoolState.awaitingValidatorInfo, "wrong state");
            assert(!validatorSet); //this should never fail
            currentState = PoolState.acceptingDeposits;
        }
        require(currentState == PoolState.acceptingDeposits, "wrong state");
        pubKey = _pubKey;
        withdrawal_credentials = _withdrawal_credentials;
        signature = _signature;
        deposit_data_root = _deposit_data_root;
        validatorSet = true;
    }

    ///@notice To withdraw funds previously deposited - ONLY works before the funds are staked. Use Claim to get rewards.
    ///@dev allows user to withdraw funds if they have not yet been deposited to the deposit contract with the Stake method
    function withdraw(uint _id, uint _amount) external mustBeAccepting {
        require(msg.sender == frensPoolShare.ownerOf(_id), "not the owner");
        require(depositForId[_id] >= _amount, "not enough deposited");
        depositForId[_id] -= _amount;
        totalDeposits -= _amount;
        (bool success, /*return data*/) = frensPoolShare.ownerOf(_id).call{value: _amount}("");
        assert(success);
    }

    ///@notice allows user to claim their portion of the rewards
    ///@dev calculates the rewards due to `_id` and sends them to the owner of `_id`
    function claim(uint _id) external correctPoolOnly(_id){
        require(
            currentState != PoolState.acceptingDeposits,
            "use withdraw when not staked"
        );
        require(
            address(this).balance > 100,
            "must be greater than 100 wei to claim"
        );
        //has the validator exited?
        bool exited;
        if (currentState != PoolState.exited) {
            IFrensOracle frensOracle = IFrensOracle(frensStorage.getAddress(keccak256(abi.encodePacked("contract.address", "FrensOracle"))));
            exited = frensOracle.checkValidatorState(address(this));
            if (exited && currentState == PoolState.staked ){
                currentState = PoolState.exited;
            }
        } else exited = true;
        //get share for id
        uint amount = _getShare(_id);
        //claim
        frenPastClaim[_id] += amount;
        totalClaims += amount;
        //fee? not applied to exited
        uint feePercent = frensStorage.getUint(keccak256(abi.encodePacked("protocol.fee.percent")));
        if (feePercent > 0 && !exited) {
            address feeRecipient = frensStorage.getAddress(keccak256(abi.encodePacked("protocol.fee.recipient")));
            uint feeAmount = (feePercent * amount) / 100;
            if (feeAmount > 1){ 
                (bool success1, /*return data*/) = feeRecipient.call{value: feeAmount - 1}(""); //-1 wei to avoid rounding error issues
                assert(success1);
            }
            amount = amount - feeAmount;
        }
        (bool success2, /*return data*/) = frensPoolShare.ownerOf(_id).call{value: amount}("");
        assert(success2);
    }

    //getters

    function getIdsInThisPool() public view returns(uint[] memory) {
      return idsInPool;
    }

    ///@return the share of the validator rewards climable by `_id`
    function getShare(uint _id) public view correctPoolOnly(_id) returns (uint) {
        return _getShare(_id);
    }

    function _getShare(uint _id) internal view returns (uint) {
        if (address(this).balance == 0) return 0;
        uint frenDep = depositForId[_id];
        uint frenPastClaims = frenPastClaim[_id];
        uint totFrenRewards = ((frenDep * (address(this).balance + totalClaims)) / totalDeposits);
        if (totFrenRewards == 0) return 0;
        uint amount = totFrenRewards - frenPastClaims;
        return amount;
    }

    ///@return the share of the validator rewards climable by `_id` minus fees. Returns 0 if pool is still accepting deposits
    ///@dev this is used for the traits in the NFT
    function getDistributableShare(uint _id) public view returns (uint) {
        if (currentState == PoolState.acceptingDeposits) {
            return 0;
        } else {
            uint share = _getShare(_id);
            uint feePercent = frensStorage.getUint(keccak256(abi.encodePacked("protocol.fee.percent")));
            if (feePercent > 0 && currentState != PoolState.exited) {
                uint feeAmount = (feePercent * share) / 100;
                share = share - feeAmount;
            }
            return share;
        }
    }

    ///@return pool state
    function getState() public view returns (string memory) {
        if (currentState == PoolState.awaitingValidatorInfo)
            return "awaiting validator info";
        if (currentState == PoolState.staked) return "staked";
        if (currentState == PoolState.acceptingDeposits)
            return "accepting deposits";
        if (currentState == PoolState.exited) return "exited";
        return "state failure"; //should never happen
    }

    function owner()
        public
        view
        override(IStakingPool, Ownable)
        returns (address)
    {
        return super.owner();
    }

    function _toWithdrawalCred(address a) private pure returns (bytes memory) {
        uint uintFromAddress = uint256(uint160(a));
        bytes memory withdralDesired = abi.encodePacked(
            uintFromAddress +
                0x0100000000000000000000000000000000000000000000000000000000000000
        );
        return withdralDesired;
    }

    ///@dev allows pool owner to change the art for the NFTs in the pool
    function setArt(IFrensArt newArtContract) external onlyOwner {
        IFrensArt newFrensArt = newArtContract;
        string memory newArt = newFrensArt.renderTokenById(1);
        require(bytes(newArt).length != 0, "invalid art contract");
        artForPool = newArtContract;
    }

    // to support receiving ETH by default
    receive() external payable {}

    fallback() external payable {}
}