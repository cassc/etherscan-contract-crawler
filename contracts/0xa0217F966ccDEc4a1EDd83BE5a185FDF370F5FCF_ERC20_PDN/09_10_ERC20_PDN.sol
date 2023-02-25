// SPDX-License-Identifier: UNLICENSED

/*
  _____               _     _               _____          ____  
 |  __ \             (_)   | |             |  __ \   /\   / __ \ 
 | |__) ___  ___  ___ _  __| | ___  _ __   | |  | | /  \ | |  | |
 |  ___/ _ \/ __|/ _ | |/ _` |/ _ \| '_ \  | |  | |/ /\ \| |  | |
 | |  | (_) \__ |  __| | (_| | (_) | | | | | |__| / ____ | |__| |
 |_|   \___/|___/\___|_|\__,_|\___/|_| |_| |_____/_/    \_\____/ 
                                                                 
*/
pragma solidity ^0.8.3; 

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol'; 
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import './IERC1155_PDN.sol';
 
contract ERC20_PDN is ERC20Upgradeable { 
    
    address public owner;

    address public ERC1155Address;
    uint public ID_ERC1155;
    uint public ratio;
    uint public ownerLock;
    uint public securityDelayInBlocks;
    bool public isAllowedToBurn;

    struct vest {
        uint amount;
        uint expirationBlockHeight;
    }

    mapping(address => vest[]) vestList;

    event ERC1155SetEvent(address indexed owner, address ERC1155address, uint ERC1155ID, uint ratio);
    event OwnerChangeEvent(address indexed oldOwner, address indexed newOwner);
    event AddVestEvent(address to, uint amount, uint durationInBlocks);
    event DeleteVestEvent(address owner, address to, uint amount);
    event WithdrawVestEvent(uint vestIndex, address receiver, uint amount);
    event SecurityDelayInBlocksEvent(address owner, uint securityDelayInBlocks);
    event IsAllowedToBurnEvent(address owner, bool isAllowed);

    modifier onlyOwner {
        require(owner == msg.sender, "ONLY_ADMIN_CAN_RUN_THIS_FUNCTION");
        _;
    }

    modifier ownerCheckBalance(address _sender, uint _amount){
        if(_sender == owner) {
            require(balanceOf(msg.sender) >= _amount + ownerLock, "NOT_ENOUGH_TOKEN");
        }
        _;
    }

    /*
    * @dev: We initialize the upgradeable smart contract with all ERC20 metadata: { name }, { symbol },
    *       { totalSupply } in wei. Automatically who initialize the smart contract is the owner
    *       of the smartcontract itself.
    *
    * Requirements:
    *       - No requirements needed
    *
    * Events:
    *       - OwnerChangeEvent: the ownership change is created
    */

    function initialize(string memory _name, string memory _symbol, uint _totalSupply) initializer public {
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _totalSupply);   
        owner = msg.sender;
        securityDelayInBlocks = uint(5760);
        emit OwnerChangeEvent(address(0), msg.sender);
    }

    /*
    * @dev: This function allows to transfer token from the unlocked owner balance to a serie of specific
    *       addesses
    *
    * Requirements:
    *       - Only the owner of the smart contract can run this function
    *       - { addresses } and { amounts } have to have the same length
    *       - every single address and every single amount inside both list can't have NULL values
    *       - Unlocked owner balance has to be greater than the sum of amounts inside the { amounts } list
    *
    * Events:
    *       - _transfer: standard ERC20 transfer event for each address and amount specified above
    */

    function runAirdrop(address[] memory _addresses, uint[] memory _amounts) public onlyOwner returns(bool){
        require(_addresses.length == _amounts.length, "DATA_DIMENSION_DISMATCH");
        uint availableOwnerBalance = balanceOf(msg.sender) - ownerLock;
        for(uint index = uint(0); index < _addresses.length; index++){
            require(_addresses[index] != address(0) && _amounts[index] != uint(0), "CANT_SET_NULL_VALUES");
            require(availableOwnerBalance >= _amounts[index], "INSUFFICIENT_OWNER_BALANCE");
            availableOwnerBalance = availableOwnerBalance - _amounts[index];
            _transfer(msg.sender, _addresses[index], _amounts[index]);
        }
        return true;
    }

    /*
    * @dev: Standard ERC20 burn function
    *
    * Events:
    *       - Standard ERC20 burn event     
    */

    function burn(uint _amount) public ownerCheckBalance(msg.sender, _amount) returns(bool){
        _burn(msg.sender, _amount);
        return true;
    }
 
    /*
    * @dev: This function allows to burn token and receive NFT in a ratio K token : 1 NFT in an integer
    *       way. It means (K + Q) token : 1 NFT if Q < K.
    *
    * Requirements:
    *       - The ERC1155 smart contract address hat to be set
    *       - The amount of token has to be greater than ratio: amount >= K
    *
    * Events:
    *       - ERC20 burn
    *       - ERC1155 mint
    */

    function burnAndReceiveNFT(uint _amount) public returns(bool){
        require(isAllowedToBurn, "FUNCTION_NOT_ENABLED");
        address tmpERC1155Address = ERC1155Address;
        require(tmpERC1155Address != address(0), "ERC1155_ADDRESS_NOT_SET");
        uint tmpRatio = ratio;
        uint NFTAmount;
        uint netBalance = (msg.sender == owner ? balanceOf(msg.sender) - ownerLock : (balanceOf(msg.sender))); 
        NFTAmount = _amount / tmpRatio;
        require(netBalance >= NFTAmount * tmpRatio, "NOT_ENOUGH_TOKEN");
        require(NFTAmount > uint(0), "NOT_ENOUGH_TOKEN_TO_RECEIVE_NFT");
        _burn(msg.sender, NFTAmount * ratio);
        IERC1155_PDN IERC1155_PDN_Interface = IERC1155_PDN(ERC1155Address);
        IERC1155_PDN_Interface.mint(msg.sender, ID_ERC1155, NFTAmount, bytes("0"));
        return true;
    }

    /*
    * @dev: This function allows to set the ERC1155 Address, the ERC1155 item ID and the ratio
    *
    * Requirements:
    *       - { ERC1155Address }, { ERC1155ID }, { RATIO } can't be set to 0 values
    *
    * Events:
    *       - ERC1155SetEvent
    */

    function setERC1155(address _ERC1155Address, uint _ID_ERC1155, uint _ratio) public onlyOwner returns(bool){
        require(_ERC1155Address != address(0), "ADDRESS_CANT_BE_NULL");
        require(_ratio > uint(0), "RATIO_CANT_BE_ZERO");
        ERC1155Address = _ERC1155Address;
        ID_ERC1155 = _ID_ERC1155;
        ratio = _ratio;
        emit ERC1155SetEvent(msg.sender, _ERC1155Address, _ID_ERC1155, _ratio);
        return true;
    }

    /*
    *     @dev: This function allows to set the delay in blocks for the new vest that will be created.
    *
    *     Requirements:
    *           - { _durationInBlocks } has to be grater or equal than 5760 blocks (1 day)
    *
    *     Events:
    *            - securityDelayInBlocksEvents
    */

    function setSecurityDelay(uint _durationInBlocks) public onlyOwner returns(bool){
        require(_durationInBlocks >= uint(5760), "NOT_ENOUGH_DURATION_IN_BLOCKS");
        securityDelayInBlocks = _durationInBlocks;
        emit SecurityDelayInBlocksEvent(msg.sender, _durationInBlocks);
        return true;
    }

    /*
    * @dev: This function allows to add a vest for a specific { address }, { amount } and { durationInBlocks }
    *
    * Requirements:
    *       - The minimum durationInBlocks is equal to 5760 blocks (1 day avg)
    *       - The available balance has to cover the vest amount
    *
    * Events:
    *       - AddVestEvent
    */

    function addVest(address _address, uint _amount, uint _durationInBlocks) public onlyOwner returns(bool){
        uint tmpOwnerLock = ownerLock;
        require(_durationInBlocks >= securityDelayInBlocks, "INSUFFICIENT_DURATION_IN_BLOCKS");
        require(balanceOf(msg.sender) - tmpOwnerLock >= _amount, "INSUFFICIENT_OWNER_BALANCE");
        vestList[_address].push(vest({
            amount: _amount,
            expirationBlockHeight: uint(block.number) + _durationInBlocks
        }));
        ownerLock = tmpOwnerLock + _amount;
        emit AddVestEvent(_address, _amount, _durationInBlocks);
        return true;
    }

    /*
    * @dev: This function allows to withdraw a Vest based on the index Vest
    *
    * Requirements:
    *       - The vest has to be set (with amount greater than 0)
    *       - The vest has to be expired
    *
    * Events:
    *       - WithdrawVestEvent
    *       - ERC20 transfer event
    */

    function withdrawVest(uint _index) public returns(bool){
        uint length = vestList[msg.sender].length;
        require(length > _index, "VEST_INDEX_DISMATCH");
        uint vestAmount = vestList[msg.sender][_index].amount;
        vestList[msg.sender][_index].amount = uint(0);
        require(vestList[msg.sender][_index].expirationBlockHeight < block.number, "VEST_NOT_EXPIRED");
        ownerLock = ownerLock - vestAmount;
        if(length > 1) vestList[msg.sender][_index] = vestList[msg.sender][length - 1];
        vestList[msg.sender].pop();
        _transfer(owner, msg.sender, vestAmount);
        emit WithdrawVestEvent(_index, msg.sender, vestAmount);
        return true;
    }

    /*
    * @dev: This function allows to get the list of available vestIndex
    */

    function getVestLength(address _address) public view returns(uint){
        return vestList[_address].length;
    }

    /*
    * @dev: This function allows to create an airdrop of vests based on a list of { addresses }, { amounts } and { durationsInBlocks }
    *
    * Requirements:
    *       - Arrays have to have the same length
    *
    * Events:
    *       - AddVestEvent for each address
    */

    function airdropVest(address[] memory _addresses, uint[] memory _amounts, uint[] memory _durationsInBlocks) public onlyOwner returns(bool){
        require(_addresses.length == _amounts.length, "DATA_DIMENSION_DISMATCH");
        require(_addresses.length == _durationsInBlocks.length, "DATA_DIMENSION_DISMATCH");
        uint tmpOwnerLock = ownerLock;
        for(uint index = uint(0); index < _durationsInBlocks.length; index++){
            require(_durationsInBlocks[index] >= securityDelayInBlocks, "INSUFFICIENT_DURATION_IN_BLOCKS");
            require(balanceOf(msg.sender) - tmpOwnerLock >= _amounts[index], "INSUFFICIENT_OWNER_BALANCE");
            vestList[_addresses[index]].push(vest({
                amount: _amounts[index],
                expirationBlockHeight: uint(block.number) + _durationsInBlocks[index]
            }));
            tmpOwnerLock = tmpOwnerLock + _amounts[index];
            emit AddVestEvent(_addresses[index], _amounts[index], _durationsInBlocks[index]);
        }
        ownerLock = tmpOwnerLock;
        return true;
    }

    /*
    * @dev: Return all vest metadata: { amount }, { expirationBlock }
    */

    function getVestMetaData(uint _index, address _address) public view returns(uint, uint){
        return (vestList[_address][_index].amount, vestList[_address][_index].expirationBlockHeight);
    }

    /*
    * @dev: This function delete a vest
    *
    * Requirements:
    *       - Only the owner can run this function
    *
    * Events:
    *       - DeleteVestEvent 
    */

    function deleteUnexpiredVests(address _address, uint _startPoint, uint _endPoint) public onlyOwner returns(bool){
        uint tmpOwnerLock = ownerLock;
        uint quantityDeleted;
        uint amount;
        uint length = vestList[_address].length;
        require(_startPoint <= _endPoint && _endPoint < length, "ENDPOINT_DISMATCH");
        for(uint index = _startPoint; index <= _endPoint; index++){
            if(vestList[_address][index - quantityDeleted].expirationBlockHeight > block.number) {
                amount = vestList[_address][index - quantityDeleted].amount;
                tmpOwnerLock = tmpOwnerLock - amount;
                vestList[_address][index - quantityDeleted] = vestList[_address][length - 1];
                vestList[_address].pop();
                quantityDeleted++;
                emit DeleteVestEvent(msg.sender, _address, amount);
            }
        }
        ownerLock = tmpOwnerLock;
        require(quantityDeleted > 0, "NO_VESTS_TO_BE_DELETED");
        return true;
    }

    function allowBurning(bool _allow) public onlyOwner returns(bool){
        isAllowedToBurn = _allow;
        emit IsAllowedToBurnEvent(msg.sender, _allow);
        return true;
    }

    function transfer(address to, uint256 amount) public ownerCheckBalance(msg.sender, amount) virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public ownerCheckBalance(from, amount) virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
}