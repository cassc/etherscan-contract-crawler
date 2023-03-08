// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Airdrop.sol";
import "./PublicAirdrop.sol";
import 'hardhat/console.sol';


contract AirdropsFactory {

    IAdmin public admin;
    address payable public feeAddr;
    
    mapping(uint256 => address) public airdropIdToAddress;
    mapping(address => address) public airdropAddressToOwner;
    mapping(address => uint256[]) public allAirdropIndexOwnedByUser;
    mapping(address => address[]) public allAirdropAddressOwnedByUser;

    // Expose so query can be possible only by position as well
    address[] public allAirdrops;
    Fee public fee;


    struct Fee{
       uint256 publicFee;
       uint256 privateFee;
    }

    event AirdropDeployed(address airdropContract);
    event AirdropOwnerAndTokenSetInFactory(
        address airdrop,
        address airdropOwner,
        address airdropToken
    );
    event LogSetFee(uint256 newFee);
    event LogSetFeeAddr(address newAddress);
    event LogWithdrawalBNB(address account, uint256 amount);

    modifier onlyAdmin() {
        require(admin.isAdmin(msg.sender), "Only Admin can deploy airdrops");
        _;
    }

    constructor(address _adminContract) {
        require(_adminContract != address(0), "Invalid address");
        admin = IAdmin(_adminContract);
    }

    function setPublicFee(uint256 _fee) public onlyAdmin {
        require(fee.publicFee != _fee, "Already set to this value");
        fee.publicFee = _fee;
        emit LogSetFee(_fee);
    }

    function setPrivateFee(uint256 _fee) public onlyAdmin {
        require(fee.privateFee != _fee, "Already set to this value");
        fee.privateFee = _fee;
        emit LogSetFee(_fee);
    }


    function setFeeAddr(address payable _feeAddr) public onlyAdmin {
        require(_feeAddr != address(0), "address zero validation");
        feeAddr = _feeAddr;
        emit LogSetFeeAddr(_feeAddr);
    }


    function deployAirdrop(address token, string[] memory _description) external payable {
        require(msg.value >= fee.privateFee, "Not enough bnb sent");

        ArborswapAirdrop airdrop = new ArborswapAirdrop(
            address(admin),
            msg.sender,
            token,
            _description
        );

        
        uint256 id = allAirdrops.length;

        airdropIdToAddress[id] = address(airdrop);
        airdropAddressToOwner[address(airdrop)] = msg.sender;
    
       
        allAirdrops.push(address(airdrop));
        allAirdropIndexOwnedByUser[msg.sender].push(id);
        allAirdropAddressOwnedByUser[msg.sender].push(address(airdrop));
        feeAddr.transfer(msg.value);

        emit AirdropDeployed(address(airdrop));
    }

    function deployPublicAirdrop(address token, string[] memory _description) external payable returns(address){
        require(msg.value >= fee.publicFee, "Not enough bnb sent");

        ArborswapPublicAirdrop airdrop = new ArborswapPublicAirdrop(
            address(admin),
            msg.sender,
            token,
            _description
        );

        
        uint256 id = allAirdrops.length;

        airdropIdToAddress[id] = address(airdrop);
        airdropAddressToOwner[address(airdrop)] = msg.sender;
    
       
        allAirdrops.push(address(airdrop));
        allAirdropIndexOwnedByUser[msg.sender].push(id);
        allAirdropAddressOwnedByUser[msg.sender].push(address(airdrop));
        feeAddr.transfer(msg.value);

        emit AirdropDeployed(address(airdrop));
        return(address(airdrop));
    }

    
    function getAllAirdropIndexOwnedByUser(address user) external view returns (uint256[] memory) {
        return allAirdropIndexOwnedByUser[user];
    }

    function getAllAirdropAddressOwnedByUser(address user) external view returns (address[] memory) {
        return allAirdropAddressOwnedByUser[user];
    }

    // Function to return number of pools deployed
    function getNumberOfAirdropsDeployed() external view returns (uint256) {
        return allAirdrops.length;
    }

    function getAirdropAddress(uint256 id) external view returns (address) {
        return airdropIdToAddress[id];
    }

    // Function
    function getLastDeployedAirdrop() external view returns (address) {
        //
        if (allAirdrops.length > 0) {
            return allAirdrops[allAirdrops.length - 1];
        }
        return address(0);
    }

    // Function to get all airdrops
    function getAllAirdrops(uint256 startIndex, uint256 endIndex)
        external
        view
        returns (address[] memory)
    {
        require(endIndex > startIndex, "Bad input");
        require(endIndex <= allAirdrops.length, "access out of rage");

        address[] memory airdrops = new address[](endIndex - startIndex);
        uint256 index = 0;

        for (uint256 i = startIndex; i < endIndex; i++) {
            airdrops[index] = allAirdrops[i];
            index++;
        }

        return airdrops;
    }

    function withdrawBNB(address payable account, uint256 amount)
        external
        onlyAdmin
    {
        require(amount <= (address(this)).balance, "Incufficient funds");
        account.transfer(amount);
        emit LogWithdrawalBNB(account, amount);
    }
}