// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "ERC20.sol";

//import "Ownable.sol";

//import "ReentrancyGuard.sol";

contract TokenC is ERC20 {
    constructor(
        string memory _name,
        string memory _ticker,
        uint256 _supply
    ) ERC20(_name, _ticker) {
        _mint(msg.sender, _supply);
    }

    function mint(address _from, uint256 _supply) public {
        _mint(_from, _supply);
    }
}

contract TokenCreate {
    address[] public tokens;
    uint256 public tokenCount;
    event TokenDeployed(address tokenAddress);

    //token => owner
    mapping(address => address) public tokenOwners;

    function deployToken(
        string calldata _name,
        string calldata _ticker,
        uint256 _supply
    ) public returns (address) {
        require(_supply > 0, "must be greater then 0");
        bytes memory emptyName = bytes(_name);
        require(emptyName.length > 0, "name cannot be null");
        bytes memory emptyTicker = bytes(_ticker);
        require(emptyTicker.length > 0, "description cannot be null");
        TokenC token = new TokenC(_name, _ticker, _supply);
        token.transfer(msg.sender, _supply);
        tokens.push(address(token));
        tokenCount += 1;
        tokenOwners[address(token)] = msg.sender;
        emit TokenDeployed(address(token));
        return address(token);
    }

    function mintToken(address _token, uint256 _supply) external {
        require(_supply > 0, "must be greater then 0");
        require(_token != address(0), "can not be 0 address");
        require(
            tokenOwners[address(_token)] == msg.sender,
            "You are not owner of this token"
        );
        TokenC myToken = TokenC(_token);

        myToken.mint(msg.sender, _supply);
    }

    function tokenBalance(address _token, address _sender)
        external
        view
        returns (uint256)
    {
        TokenC myToken = TokenC(_token);
        return myToken.balanceOf(_sender);
    }

    /*function returnToken() external view returns (address[] memory) {
        uint256 jj;
        for (uint256 ii = 0; ii < tokens.length; ii++) {
            if (tokenOwners[address(tokens[ii])] == msg.sender) {
                jj++;
            }
        }

        uint256 count = jj;
        address[] memory tokenList = new address[](count);

        uint256 j;

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenOwners[address(tokens[i])] == msg.sender) {
                tokenList[j] = tokens[i];
                j++;
            }
        }
        return tokenList;
    }*/

    struct tokensStruct {
        address token;
        string name;
        string symbol;
    }

    function returnToken2(address _sender)
        external
        view
        returns (tokensStruct[] memory)
    {
        //address[] memory tokenList;
        uint256 jj;
        for (uint256 ii = 0; ii < tokens.length; ii++) {
            if (tokenOwners[address(tokens[ii])] == _sender) {
                jj++;
            }
        }

        uint256 count = jj;

        uint256 j;

        tokensStruct[] memory tokenStructs = new tokensStruct[](count);

        // An array of 'Todo' struc

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokenOwners[address(tokens[i])] == _sender) {
                TokenC myToken = TokenC(tokens[i]);
                tokenStructs[j].token = tokens[i];
                tokenStructs[j].name = myToken.name();
                tokenStructs[j].symbol = myToken.symbol();
                j++;
            }
        }
        return tokenStructs;
    }

    constructor() public {}
}