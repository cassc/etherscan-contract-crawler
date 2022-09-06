// SPDX-License-Identifier:  MIT

/*
 * @title Payroll3 v0.1
 * @author Marcus J. Carey, @marcusjcarey
 * @notice Payroll3 extended OpenZeppelin's PaymentSplitter DeFi Contract
 */

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/finance/PaymentSplitter.sol';

contract Payroll3 is PaymentSplitter {
    bool public archived;
    string public name;
    address internal owner;
    string public primaryToken;
    uint256 public releasableDate;

    address[] internal _payees_;
    uint256[] internal _shares_;
    bool public stream;
    address[] public tokens;

    constructor(
        string memory _name,
        address _owner,
        string memory _primaryToken,
        uint256 _releasableDate,
        address[] memory _payees,
        uint256[] memory _shares,
        address[] memory _tokens,
        bool _stream
    ) payable PaymentSplitter(_payees, _shares) {
        archived = false;
        name = _name;
        owner = _owner;
        primaryToken = _primaryToken;
        releasableDate = _releasableDate;
        _payees_ = _payees;
        _shares_ = _shares;
        tokens = _tokens;
        stream = _stream;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            'Message sender is not the owner of contract!'
        );
        _;
    }

    modifier isVested() {
        require(
            block.timestamp > releasableDate,
            'Unable to release funds prior to set releasable date!'
        );
        _;
    }

    function contractAddress() external view returns (address) {
        return address(this);
    }

    function getPayees() external view returns (address[] memory) {
        return _payees_;
    }

    function getShares() external view returns (uint256[] memory) {
        return _shares_;
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    function balanceOfToken(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function release(address payable account) public override isVested {
        super.release(account);
    }

    function release(IERC20 token, address account) public override isVested {
        super.release(token, account);
    }

    function streamETH() public payable {
        if (address(this).balance > 0) {
            for (uint256 i = 0; i < _payees_.length; i++) {
                if (releasable(_payees_[i]) > 0) {
                    release(payable(_payees_[i]));
                }
            }
        }
    }

    function streamTokens() public payable {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                for (uint256 j = 0; j < _payees_.length; j++) {
                    if (releasable(token, _payees_[j]) > 0) {
                        release(token, _payees_[j]);
                    }
                }
            }
        }
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function updateConfig(
        bool _stream,
        bool _archived,
        string memory _name,
        address[] memory _tokens
    ) public onlyOwner {
        stream = _stream;
        archived = _archived;
        name = _name;
        tokens = _tokens;
    }

    function updatePrimaryToken(string memory _primaryToken)
        external
        onlyOwner
    {
        primaryToken = _primaryToken;
    }

    receive() external payable override {
        if (stream) {
            streamETH();
        }
    }

    fallback() external payable {}
}