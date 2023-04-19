/**
 *Submitted for verification at BscScan.com on 2023-04-19
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
    event Collect(bool status, address indexed collector, uint256 collNum, uint256 timestamp);
    event CollectAll(bool status, address indexed collector, uint256 tokenBalance, uint256 timestamp);
    struct Receord {
        address depositer;
        uint256 amount;
    }
    Receord[] private historyReceords;
    mapping(address => uint256[]) indexs;
    mapping(address => uint256) collectorIndex;

    address[] private collectors;

    TokenCollector public _tokenCollector;

    enum CollectorError {
        NoError,
        InvalidCollector,
        InvalidCollectorLength,
        InvalidCollectors,
        InvalidCollectorV, // Deprecated in v4.8
        ExistedCollector
    }

    function _throwError(CollectorError error) private pure {
        if (error == CollectorError.NoError) {
            return; // no error: do nothing
        } else if (error == CollectorError.InvalidCollector) {
            revert("COLL: invalid collector");
        } else if (error == CollectorError.InvalidCollectorLength) {
            revert("COLL: invalid collector length");
        } else if (error == CollectorError.InvalidCollectors) {
            revert("COLL: invalid collector 's' value");
        } else if (error == CollectorError.ExistedCollector) {
            revert("COLL: existed collector");
        }
    }

    function createCollector() external onlyOwner returns(address) {
        _tokenCollector = new TokenCollector(address(BUSD));
        (CollectorError error) = _addCollector(address(_tokenCollector));
        _throwError(error);
        return address(_tokenCollector);
    }

    function isCollector(address addr) public view returns(bool) {
        require(addr != address(0), "COLL: Query address is zero");
        uint256 index = collectorIndex[addr];
        if(collectors[index] == addr) {
            return true;
        }
        return false;
    }

    function getCollectorCount() public view returns(uint256) {
        uint256 length = collectors.length;
        return length;
    }

    function withdrawToken(IERC20 token, uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }

    function collect(address collector, uint256 collCount) external onlyOwner returns (bool, address, uint256, uint256) {
        require(isCollector(collector), "COLL: invalid collector"); 
        
        address collAdr = collector;
        uint256 collNum = collCount;
        uint256 tokenBalance = BUSD.balanceOf(collAdr);
        if(collNum > tokenBalance) {
            collNum = tokenBalance;
        }
        if (tokenBalance > 0) {
            BUSD.transferFrom(collAdr, rec, collNum);
            historyReceords.push(Receord({depositer: collAdr, amount: collNum}));
            uint256 counter = historyReceords.length - 1;
            indexs[collAdr].push(counter);
        }

        //emit Collect(true, collAdr, collNum, block.timestamp);

        return(true, collAdr, collNum, block.timestamp);
    }

    function collectAll(address collector) external onlyOwner returns (bool, address, uint256, uint256) {
        require(isCollector(collector), "COLL: invalid collector"); 
        
        address collAdr = collector;
        uint256 tokenBalance = BUSD.balanceOf(collAdr);
        if (tokenBalance > 0) {
            BUSD.transferFrom(collAdr, rec, tokenBalance);
            historyReceords.push(Receord({depositer: collAdr, amount: tokenBalance}));
            uint256 counter = historyReceords.length - 1;
            indexs[collAdr].push(counter);
        }

        //emit CollectAll(true, collAdr, tokenBalance, block.timestamp);

        return(true, collAdr, tokenBalance, block.timestamp);
    }

    function _addCollector(address adr) private returns (CollectorError) {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size <= 0) {
            return (CollectorError.InvalidCollector);
        }
        if (0 == collectorIndex[adr]) {
            if (0 == collectors.length || collectors[0] != adr) {
                collectorIndex[adr] = collectors.length;
                collectors.push(adr);
                return (CollectorError.NoError);
            } else {
                return (CollectorError.ExistedCollector);
            }
        } else {
            return (CollectorError.ExistedCollector);
        }
    }

    function getValues() public pure returns (uint256, uint256) {
        uint256 a = 1;
        uint256 b = 2;
        return (a, b);
    }
}