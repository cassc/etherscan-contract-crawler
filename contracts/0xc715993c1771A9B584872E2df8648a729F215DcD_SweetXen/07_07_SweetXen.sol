// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IXEN.sol";
import "./interfaces/IXENTorrent.sol";
import "./interfaces/IXENProxying.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SweetXen is Ownable, IXENTorrent, IXENProxying {
    address private immutable _original;

    address public immutable xenCrypto;

    bytes private _miniProxy;

    mapping(address => uint256) public countBulkClaimRank;

    mapping(address => uint256) public countBulkClaimMintReward;

    uint256 public totalSupplyBulkClaimRank;

    uint256 public totalSupplyBulkClaimMintReward;

    constructor(address xenCrypto_) {
        require(xenCrypto_ != address(0));
        _original = address(this);
        xenCrypto = xenCrypto_;
        _miniProxy = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
    }

    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.claimRank(term)
     */
    function callClaimRank(uint256 term) external {
        require(msg.sender == _original, "unauthorized");
        IXEN(xenCrypto).claimRank(term);
    }

    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.claimMintRewardAndShare()
     */
    function callClaimMintReward(address to) external {
        require(msg.sender == _original, "unauthorized");
        IXEN(xenCrypto).claimMintRewardAndShare(to, uint256(100));
        if (address(this) != _original) {
            selfdestruct(payable(tx.origin));
        }
    }

    /**
        @dev main torrent interface. initiates Bulk Mint (Torrent) Operation
     */
    function bulkClaimRank(uint256 users, uint256 term) public {
        require(users > 0, "Illegal count");
        require(term > 0, "Illegal term");
        bytes memory bytecode = _miniProxy;
        bytes memory callData = abi.encodeWithSignature(
            "callClaimRank(uint256)",
            term
        );
        address proxy;
        bool succeeded;
        uint256 cbcr = countBulkClaimRank[msg.sender];
        for (uint256 i = cbcr; i < cbcr + users; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            assembly {
                proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            require(succeeded, "Error while claiming rank");
        }
        countBulkClaimRank[msg.sender] = cbcr + users;
        totalSupplyBulkClaimRank = totalSupplyBulkClaimRank + users;
        emit BulkClaimRank(msg.sender, users, term);
    }

    function proxyFor(
        address sender,
        uint256 i
    ) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"ff",
                address(this),
                salt,
                keccak256(_miniProxy)
            )
        );
        proxy = address(uint160(uint256(hash)));
    }

    /**
        @dev main torrent interface. initiates Mint Reward claim and collection and terminates Torrent Operation
     */
    function bulkClaimMintReward(uint256 users) external {
        require(
            countBulkClaimRank[msg.sender] > 0,
            "No BulkClaimRank record yet"
        );
        bytes memory callData = abi.encodeWithSignature(
            "callClaimMintReward(address)",
            msg.sender
        );
        uint256 bcr = countBulkClaimRank[msg.sender];
        uint256 bcmr = countBulkClaimMintReward[msg.sender];
        uint256 sc = bcmr + users < bcr ? bcmr + users : bcr;
        uint256 rsi;
        for (uint256 i = bcmr; i < sc; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            bool succeeded;
            assembly {
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            require(succeeded, "Error while claiming rewards");
            rsi++;
        }
        countBulkClaimMintReward[msg.sender] = sc;
        totalSupplyBulkClaimMintReward = totalSupplyBulkClaimMintReward + rsi;
        emit BulkClaimMintReward(msg.sender, users);
    }

    function bulkClaimMintRewardIndex(
        uint256 _userIndex,
        uint256 _userEnd
    ) external {
        require(_userIndex < _userEnd, "Illegal UserIndex");
        require(
            countBulkClaimRank[msg.sender] > 0,
            "No BulkClaimRank record yet"
        );
        require(
            _userEnd <= countBulkClaimRank[msg.sender],
            "Illegal UserIndex"
        );
        bytes memory callData = abi.encodeWithSignature(
            "callClaimMintReward(address)",
            msg.sender
        );
        uint256 rsi;
        for (uint i = _userIndex; i <= _userEnd; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            bool succeeded;
            assembly {
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            require(succeeded, "Error while claiming rewards");
            rsi++;
        }
        totalSupplyBulkClaimMintReward = totalSupplyBulkClaimMintReward + rsi;
        emit BulkClaimMintRewardIndex(msg.sender, _userIndex, _userEnd);
    }

    function _contractExists(address proxy) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(proxy)
        }
        return size > 0;
    }

    function withdraw(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No balance to withdraw");
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "Failed to withdraw payment");
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 _ercBalance = erc20token.balanceOf(address(this));
        require(_ercBalance > 0, "No balance to withdraw");
        bool _ercSuccess = erc20token.transfer(owner(), _ercBalance);
        require(_ercSuccess, "Failed to withdraw payment");
    }

    receive() external payable virtual {}
}