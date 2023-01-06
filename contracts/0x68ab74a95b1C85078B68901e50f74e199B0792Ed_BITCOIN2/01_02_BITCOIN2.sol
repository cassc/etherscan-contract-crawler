// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/BITCOIN2.sol";

contract $Context is Context {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_msgSender() external view returns (address payable) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}

abstract contract $IERC20 is IERC20 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

contract $SafeMath {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $add(uint256 a,uint256 b) external pure returns (uint256) {
        return SafeMath.add(a,b);
    }

    function $sub(uint256 a,uint256 b) external pure returns (uint256) {
        return SafeMath.sub(a,b);
    }

    function $sub(uint256 a,uint256 b,string calldata errorMessage) external pure returns (uint256) {
        return SafeMath.sub(a,b,errorMessage);
    }

    function $mul(uint256 a,uint256 b) external pure returns (uint256) {
        return SafeMath.mul(a,b);
    }

    function $div(uint256 a,uint256 b) external pure returns (uint256) {
        return SafeMath.div(a,b);
    }

    function $div(uint256 a,uint256 b,string calldata errorMessage) external pure returns (uint256) {
        return SafeMath.div(a,b,errorMessage);
    }

    function $mod(uint256 a,uint256 b) external pure returns (uint256) {
        return SafeMath.mod(a,b);
    }

    function $mod(uint256 a,uint256 b,string calldata errorMessage) external pure returns (uint256) {
        return SafeMath.mod(a,b,errorMessage);
    }

    receive() external payable {}
}

contract $Address {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $functionCall_address_bytes_Returned(bytes arg0);

    event $functionCall_address_bytes_string_Returned(bytes arg0);

    event $functionCallWithValue_address_bytes_uint256_Returned(bytes arg0);

    event $functionCallWithValue_address_bytes_uint256_string_Returned(bytes arg0);

    constructor() {}

    function $isContract(address account) external view returns (bool) {
        return Address.isContract(account);
    }

    function $sendValue(address payable recipient,uint256 amount) external payable {
        return Address.sendValue(recipient,amount);
    }

    function $functionCall(address target,bytes calldata data) external payable returns (bytes memory) {
        (bytes memory ret0) = Address.functionCall(target,data);
        emit $functionCall_address_bytes_Returned(ret0);
        return (ret0);
    }

    function $functionCall(address target,bytes calldata data,string calldata errorMessage) external payable returns (bytes memory) {
        (bytes memory ret0) = Address.functionCall(target,data,errorMessage);
        emit $functionCall_address_bytes_string_Returned(ret0);
        return (ret0);
    }

    function $functionCallWithValue(address target,bytes calldata data,uint256 value) external payable returns (bytes memory) {
        (bytes memory ret0) = Address.functionCallWithValue(target,data,value);
        emit $functionCallWithValue_address_bytes_uint256_Returned(ret0);
        return (ret0);
    }

    function $functionCallWithValue(address target,bytes calldata data,uint256 value,string calldata errorMessage) external payable returns (bytes memory) {
        (bytes memory ret0) = Address.functionCallWithValue(target,data,value,errorMessage);
        emit $functionCallWithValue_address_bytes_uint256_string_Returned(ret0);
        return (ret0);
    }

    receive() external payable {}
}

contract $Ownable is Ownable {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function $_msgSender() external view returns (address payable) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}

abstract contract $IUniswapV2Factory is IUniswapV2Factory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

abstract contract $IUniswapV2Pair is IUniswapV2Pair {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

abstract contract $IUniswapV2Router01 is IUniswapV2Router01 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

abstract contract $IUniswapV2Router02 is IUniswapV2Router02 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

contract $BITCOIN2 is BITCOIN2 {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event $_basicTransfer_Returned(bool arg0);

    event $takeFee_Returned(uint256 arg0);

    constructor(string memory coinName, string memory coinSymbol, uint8 coinDecimals, uint256 supply, address router, address owner, address marketingAddress, address teamAddress, address service) BITCOIN2(coinName, coinSymbol, coinDecimals, supply, router, owner, marketingAddress, teamAddress, service) {}

    function $_balances(address arg0) external view returns (uint256) {
        return _balances[arg0];
    }

    function $inSwapAndLiquify() external view returns (bool) {
        return inSwapAndLiquify;
    }

    function $_basicTransfer(address sender,address recipient,uint256 amount) external returns (bool) {
        (bool ret0) = super._basicTransfer(sender,recipient,amount);
        emit $_basicTransfer_Returned(ret0);
        return (ret0);
    }

    function $takeFee(address sender,address recipient,uint256 amount) external returns (uint256) {
        (uint256 ret0) = super.takeFee(sender,recipient,amount);
        emit $takeFee_Returned(ret0);
        return (ret0);
    }

    function $_msgSender() external view returns (address payable) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}