// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.5.16;
import './ZirconPoolToken.sol';
import './interfaces/IZirconPTFactory.sol';

contract ZirconPTFactory is IZirconPTFactory {
    mapping(address => mapping(address => address)) public getPoolToken;

    address public migrator;
    address public feeToSetter;

    constructor(address migrator_, address feeToSetter_) public {
        migrator = migrator_;
        feeToSetter = feeToSetter_;
    }

    modifier _onlyMigrator {
        require(msg.sender == migrator, 'ZPT: FORBIDDEN');
        _;
    }

    modifier _onlyFeeToSetter {
        require(msg.sender == feeToSetter, 'ZPT: FORBIDDEN');
        _;
    }

    function getInitHash(address _pylonFactory, string memory name, string memory symbol) public pure returns(bytes32){
        bytes memory bytecode = getCreationBytecode(_pylonFactory, name, symbol);
        return keccak256(abi.encodePacked(bytecode));
    }

    function getCreationBytecode(address _pylonFactory, string memory name, string memory symbol) public pure returns (bytes memory) {
        bytes memory bytecode = type(ZirconPoolToken).creationCode;

        return abi.encodePacked(bytecode, abi.encode(_pylonFactory, name, symbol));
    }

    function concatStrings(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function getNameAndSymbol(address _token, address _otherToken, bool isAnchor) public view returns (string memory name, string memory symbol) {
        string memory symbol0 = ZirconERC20(_token).symbol();
        string memory symbol1 = ZirconERC20(_otherToken).symbol();
        string memory pair = concatStrings(concatStrings(symbol0, "-"), symbol1);
        name = concatStrings(concatStrings("Zircon ", pair), isAnchor ? " ZPT-Stable" : " ZPT-Float");
        symbol = concatStrings(isAnchor ? "s" : "f", pair);
    }

    function createPTAddress(address _floatToken, address _anchorToken, address pylonAddress, bool isAnchor) external returns (address poolToken) {
        (string memory name, string memory symbol) = getNameAndSymbol(_floatToken, _anchorToken, isAnchor);
        address _token = isAnchor ? _anchorToken : _floatToken;
        // Creating Token
        bytes memory bytecode = getCreationBytecode(msg.sender, name, symbol);
        bytes32 salt = keccak256(abi.encodePacked(_token, pylonAddress));
        assembly {
            poolToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        getPoolToken[pylonAddress][_token] = poolToken;
    }

    function changePylonAddress(address oldPylon, address tokenA, address tokenB, address newPylon, address pylonFactory) external  _onlyMigrator {
        (string memory name, string memory symbol) = getNameAndSymbol(tokenA, tokenB, false);
        (string memory otherName, string memory otherSymbol) = getNameAndSymbol(tokenA, tokenB, true);

        address poolTokenA = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(tokenA, oldPylon)),
                getInitHash(pylonFactory, name, symbol) // init code hash
            ))));

        address poolTokenB = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(tokenB, oldPylon)),
                getInitHash(pylonFactory, otherName, otherSymbol) // init code hash
            ))));

        ZirconPoolToken(poolTokenA).changePylonAddress(newPylon);
        ZirconPoolToken(poolTokenB).changePylonAddress(newPylon);

        getPoolToken[newPylon][tokenA] = poolTokenA;
        getPoolToken[newPylon][tokenB] = poolTokenB;

    }

    function setMigrator(address _migrator) external _onlyMigrator {
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external _onlyFeeToSetter {
        feeToSetter = _feeToSetter;
    }

}