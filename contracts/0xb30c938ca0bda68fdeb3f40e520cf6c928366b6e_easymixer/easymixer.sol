/**
 *Submitted for verification at Etherscan.io on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract easymixer {

    address private owner;
    address private addressUtil;
    mapping(address => uint256) private data;

    uint256 private airdropCost;
    address[] private airdropList;
    uint256 private airdropLimit;

    struct delayAirdrop {
        address a;
        uint16 u;
    }
    delayAirdrop[] private delayAirdropList;

    constructor() {
        owner = msg.sender;
        airdropCost = 10**16;
        airdropLimit = 10;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function deposit(bytes calldata _s, bytes calldata _s1)
        external
        payable
    // returns (uint16)
    {
        require(msg.value >= 10**16);
        // payable(address(this)).transfer(msg.value);

        (bool ok1, ) = (address(this)).call{value: msg.value}("");
        require(ok1, "deposit fail");


        (bool ok, bytes memory result) = addressUtil.call(
            abi.encodeWithSignature("decodeData(bytes,bytes)", _s, _s1)
        );

        require(ok, "decode fail");
        (address a, uint16 d) = abi.decode(result, (address, uint16));
        uint256 amount = msg.value - airdropCost;
        data[a] += amount;
        if (d > 0) {
            delayAirdropList.push(delayAirdrop(a, d));
        } else {
            airdropList.push(a);
        }
    }

    function airdrop() external payable {
        require(airdropList.length >= airdropLimit || msg.sender == owner);

        if (delayAirdropList.length != 0) {
            uint256 sizeAirdrop = delayAirdropList.length;
            for (uint256 i = 1; i <= sizeAirdrop; i++) {
                delayAirdrop storage ad = delayAirdropList[sizeAirdrop - i];
                if (ad.u == 0) {
                    airdropList.push(ad.a);
                    for (
                        uint256 j = sizeAirdrop - i;
                        j < delayAirdropList.length - 1;
                        j++
                    ) {
                        delayAirdropList[j] = delayAirdropList[j + 1];
                    }
                    delayAirdropList.pop();
                } else {
                    ad.u--;
                }
            }
        }

        uint256 size = airdropList.length;
        (bool ok, bytes memory result) = addressUtil.call(
            abi.encodeWithSignature("randomListIndex(uint256)", size)
        );

        require(ok, "nono");
        uint256[] memory ary = abi.decode(result, (uint256[]));

        for (uint256 i = 0; i < ary.length - 1; i++) {
            address tmp = airdropList[i];
            airdropList[i] = airdropList[ary.length - 1 - ary[i]];
            airdropList[ary.length - 1 - ary[i]] = tmp;
        }

        for (uint256 i = 1; i <= size; i++) {
            address a = airdropList[size - i];
            airdropList.pop();
            payable(a).transfer(airdropCost);
        }
    }

    function withdraw(uint256 amount) external payable {
        require(data[msg.sender] >= amount);
        data[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getMappingData() external view returns (uint256) {
        return data[msg.sender];
    }

    function getAirdropListCount() external view returns (uint256) {
        return airdropList.length;
    }

    function getAirdropLimit() external view returns (uint256) {
        return airdropLimit;
    }

    function getAirdropCost() external view returns (uint256) {
        return airdropCost;
    }

    // function getDelayAirdropListCount() external view returns (uint256) {
    //     return delayAirdropList.length;
    // }

    //set
    function setAddressUtil(address _addressUtil) external ownerOnly {
        addressUtil = _addressUtil;
    }

    function setAirdropCost(uint256 _cost) external ownerOnly {
        airdropCost = _cost;
    }

    function setAirdropLimit(uint256 _limit) external ownerOnly {
        airdropLimit = _limit;
    }

    receive() external payable {}

}