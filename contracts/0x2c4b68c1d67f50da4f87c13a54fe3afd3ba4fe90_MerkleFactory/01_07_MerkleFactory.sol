// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./MerkleChild.sol";

contract MerkleFactory is Ownable {
    mapping(address => address[]) private tokenAirdrops;
    mapping(address => address[]) private creatorAirdrops;
    mapping(address => string) public airdropUserList;
    address[] private allAirdrops;

    IERC20 public immutable weth;
    uint256 public creatorFee = 0.01 ether;
    uint256 public claimFee = 0.003 ether;
    address payable public feeAddress;

    uint256 public minClaimPeriod = 14 days;
    uint256 public maxClaimPeriod = 90 days;

    constructor(address _weth) {
        weth = IERC20(_weth);
        feeAddress = payable(msg.sender);
    }

    function createNewAirdrop(
        bool _isPayingInToken,
        address _token,
        uint256 _amount,
        uint256 _startDate,
        uint256 _endDate,
        string memory _url,
        bytes32 _merkleRoot
    ) external payable {
        uint256 duration = _endDate - _startDate;
        require(duration >= minClaimPeriod && duration <= maxClaimPeriod, "Invalid duration to claim airdrop");
        require(_amount > 0, "Zero amount");

        MerkleChild newAirdrop = new MerkleChild(
            _token,
            payable(msg.sender),
            feeAddress,
            _startDate,
            _endDate,
            _merkleRoot
        );
        airdropUserList[address(newAirdrop)] = _url;

        if (_isPayingInToken) {
            weth.transferFrom(msg.sender, feeAddress, creatorFee);
        } else {
            require(msg.value >= creatorFee, "Fees not paid");
            feeAddress.transfer(creatorFee);
        }

        allAirdrops.push(address(newAirdrop));
        tokenAirdrops[_token].push(address(newAirdrop));
        creatorAirdrops[msg.sender].push(address(newAirdrop));

        if (_token == address(0)) {
            /* solhint-disable-next-line */
            (bool success, ) = address(newAirdrop).call{ value: _amount }("");
            require(success, "");
        } else {
            IERC20(_token).transferFrom(msg.sender, address(newAirdrop), _amount);
        }
    }

    function setFees(
        address payable _newAddress,
        uint256 _creatorFee,
        uint256 _claimFee
    ) external onlyOwner {
        feeAddress = _newAddress;
        creatorFee = _creatorFee;
        claimFee = _claimFee;
    }

    function setClaimPeriod(uint256 min, uint256 max) external onlyOwner {
        minClaimPeriod = min;
        maxClaimPeriod = max;
    }

    function getAllTokenAirdrops(address _token) public view returns (address[] memory) {
        return tokenAirdrops[_token];
    }

    function getAllCreatorAirdrops(address _creator) public view returns (address[] memory) {
        return creatorAirdrops[_creator];
    }

    function getAllAirdrops() public view returns (address[] memory) {
        return allAirdrops;
    }

    function getAllAirdropsByIndex(uint256 startIdx, uint256 endIdx) public view returns (address[] memory) {
        if (endIdx > allAirdrops.length - 1) {
            endIdx = allAirdrops.length - 1;
        }
        address[] memory list = new address[](endIdx - startIdx + 1);
        uint256 counter = 0;

        for (uint256 i = startIdx; i <= endIdx; i++) {
            list[counter] = allAirdrops[i];
            counter++;
        }
        return list;
    }
}