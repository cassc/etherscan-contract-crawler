/**
 *Submitted for verification at BscScan.com on 2022-12-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IFeeTo {
    function setTeam(address newTeam) external;
}

contract FeeTo {

    address public dev;
    address public dev1;
    address public team;
    uint256 public devCut = 100;
    uint256 public dev1Cut = 100;

    address public constant FeeToo = 0x8de2bc99DcB41186A0a7410B21e0FC973B601eb8;

    address[] public tokens;

    modifier onlyDev() {
        require(
            msg.sender == dev,
            'Only Dev'
        );
        _;
    }

    modifier onlyTeam() {
        require(
            msg.sender == team,
            'Only Dev'
        );
        _;
    }

    constructor() {
        dev = 0xa7C372be1F2fbcDFE6FaF7694aCA2Fe4cf693Eb1;
        dev1 = 0x6d08707a6E3e037e9c81a714818e7F9eA90CB3d8;
        team = 0xe9C1Badb6d12eaE0f6d4aEfE2480346ed94C673c;
    }

    function addToken(address token) external onlyTeam {
        tokens.push(token);
    }

    function setDev(address newDev) external onlyTeam {
        dev = newDev;
    }

    function setDevCut(uint newCut) external onlyTeam {
        require(newCut <= 1000, 'Cut Too High');
        devCut = newCut;
    }

    function setDev1(address newDev1) external onlyTeam {
        dev1 = newDev1;
    }

    function setDev1Cut(uint newCut) external onlyTeam {
        require(newCut <= 1000, 'Cut Too High');
        dev1Cut = newCut;
    }

    function setTeam(address newTeam) external onlyTeam {
        team = newTeam;
    }

    function setToNewSplitter(address newSplitter) external onlyTeam {
        IFeeTo(FeeToo).setTeam(newSplitter);
    }

    function withdraw(address token) external {
        _withdraw(token);
    }

    function withdrawBatch(address[] calldata _tokens) external {
        uint len = _tokens.length;
        for (uint i = 0; i < len;) {
            _withdraw(_tokens[i]);
            unchecked { ++i; }
        }
    }

    function withdrawFromTokenList() external {
        uint len = tokens.length;
        for (uint i = 0; i < len;) {
            _withdraw(tokens[i]);
            unchecked { ++i; }
        }
    }

    function _withdraw(address token) internal {
        uint bal = IERC20(token).balanceOf(address(this));
        if (bal <= 1000) {
            return;
        }

        uint fDev = bal * devCut / 1000;
        uint fDev1 = bal * dev1Cut / 1000;
        uint fTeam = bal - ( fDev + fDev1 );

        if (fDev > 0) {
            IERC20(token).transfer(dev, fDev);
        }
        if (fDev1 > 0) {
            IERC20(token).transfer(dev1, fDev1);
        }
        if (fTeam > 0) {
            IERC20(token).transfer(team, fTeam);
        }
    }

    function viewTokens() external view returns (address[] memory) {
        return tokens;
    }
}