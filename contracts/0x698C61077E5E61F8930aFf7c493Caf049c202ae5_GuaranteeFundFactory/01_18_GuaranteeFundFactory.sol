// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGuaranteeFund {
    function initialize(
        string memory domain,
        address owner,
        address factory,
        address token,
        uint256 amount
    ) external;

    function upgradeTo(address newImplementation) external;
}

contract GuaranteeFundFactory is Ownable, Initializable, UUPSUpgradeable {
    address public guaranteeFundImpl;
    address[] public guaranteeFunds;

    mapping(address => uint256) public guaranteeFundIndex;
    mapping(string => address) public domainToGuaranteeFund;

    event NewGuaranteeFund(
        string domain,
        address guaranteeFund,
        address guarantor,
        address token,
        uint256 amount
    );

    function getGuaranteeFund(
        string memory _domain
    ) external view returns (address) {
        return domainToGuaranteeFund[_domain];
    }

    function initialize(address _guaranteeFundImpl) public initializer {
        guaranteeFundImpl = _guaranteeFundImpl;
        _transferOwnership(_msgSender());
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {}

    function upgradeGuaranteeFund(address _newImpl) external onlyOwner {
        guaranteeFundImpl = _newImpl;
        for (uint256 i = 0; i < guaranteeFunds.length; i++) {
            IGuaranteeFund(guaranteeFunds[i]).upgradeTo(_newImpl);
        }
    }

    /**
     * @dev Create a new guarantee fund.
     * @param _domain The domain name of the guarantee fund.
     * @param _token The token used for the guarantee fund.
     * @param _amount The amount of guarantee fund.
     * @return The address of the created guarantee fund.
     */
    function newGuaranteeFund(
        string memory _domain,
        address _token,
        uint256 _amount
    ) external payable returns (address) {
        require(
            domainToGuaranteeFund[_domain] == address(0),
            "GuaranteeFundFactory: domain exists"
        );

        if (_token == address(0)) {
            require(
                msg.value >= _amount,
                "GuaranteeFundFactory: not enough value"
            );
        } else {
            IERC20 token = IERC20(_token);
            require(
                token.allowance(msg.sender, address(this)) >= _amount,
                "GuaranteeFundFactory: not enough allowance"
            );
        }

        bytes memory deployCode = abi.encodeCall(
            IGuaranteeFund.initialize,
            (_domain, owner(), address(this), _token, _amount)
        );
        ERC1967Proxy guaranteeFundProxy = new ERC1967Proxy(
            guaranteeFundImpl,
            deployCode
        );
        address guaranteeFund = address(guaranteeFundProxy);
        guaranteeFunds.push(guaranteeFund);
        guaranteeFundIndex[guaranteeFund] = guaranteeFunds.length - 1;
        domainToGuaranteeFund[_domain] = guaranteeFund;

        // transfer token to guarantee fund
        if (_token == address(0)) {
            (bool success, ) = guaranteeFund.call{value: _amount}("");
            require(
                success,
                "GuaranteeFundFactory: transfer value to guarantee fund failed"
            );
        } else {
            IERC20 token = IERC20(_token);
            token.transferFrom(msg.sender, guaranteeFund, _amount);
        }

        emit NewGuaranteeFund(
            _domain,
            guaranteeFund,
            msg.sender,
            _token,
            _amount
        );

        return guaranteeFund;
    }
}