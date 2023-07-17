// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @creator: URN DAO
/// @author: Wizard

/*
              ▄▓████████████▓▄        ,▄▄▓█████▌
           ▄█████████████████▓▓▓      █████████
         ▓███████▀       ╙███████▌   ▐████████
       ┌████████           ╙██████▌  ████▓██▓
      ╒████████▌             ██████▌┌███████▀
      ████▓▓███              └█████████████▀
     ╫████████▌               ╟███████████▀
     █████████▌                ████▓█████▀
     █████████▌                █████████▀
     █████████▌                ╟███████▀
     ╫█████████                ████████▌
      ████▓▓███▌              ▓█████████
      ╙█████████             ███████████▌
       ╙█████████▄         ▄████▓███████▓▄
         █████▓████▄▄▄▄▄▄▓█████▀ ╘█████████▓▄▄▓███▌
           ▀█████████████████▀    ╙██▓███████████▀
              ╙▀▀██ALPHA██▀▀         ╙▀██████▀▀
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IMerge is IERC165 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function massOf(uint256 tokenId) external view returns (uint256);

    function tokenOf(address owner) external view returns (uint256);
}

interface IGenesis {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}

contract Alpha is ERC20, IERC721Receiver, Pausable {
    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant INTERN_VALUE = 1133834140555500000;

    IMerge public merge;
    IGenesis public genesis;
    address public dev;
    address public urn;
    address public vault;

    uint256 public devFee = 100;
    uint256 public urnFee = 400;

    uint256 public maxMass = 10;

    event Received(address from, uint256 tokenId, uint256 mass);

    modifier onlyUrn() {
        require(_msgSender() == urn, "caller is not urn");
        _;
    }

    constructor(
        address _dev,
        address _urn,
        address _vault,
        address _genesis,
        address _merge,
        uint256 _alpha
    ) ERC20(".alpha", unicode"α") {
        dev = _dev;
        urn = _urn;
        vault = _vault;
        merge = IMerge(_merge);
        genesis = IGenesis(_genesis);

        // initial .merge supply
        _mint(_msgSender(), _alpha * (10**uint256(18)));
    }

    function setMaxMerge(uint256 _maxMass) public virtual onlyUrn {
        maxMass = _maxMass;
    }

    function setUrnFee(uint256 _fee) public virtual onlyUrn {
        urnFee = _fee;
    }

    function setDevFee(uint256 _fee) public virtual onlyUrn {
        devFee = _fee;
    }

    function setUrn(address _urn) public virtual onlyUrn {
        urn = _urn;
    }

    function setDev(address _dev) public virtual {
        require(_msgSender() == dev, "caller is not dev");
        dev = _dev;
    }

    function setVault(address _vault) public virtual onlyUrn {
        vault = _vault;
    }

    function unpause() public virtual onlyUrn {
        _unpause();
    }

    function pause() public virtual onlyUrn {
        _pause();
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function _mint(
        address to,
        uint256 amount,
        bool hasFee
    ) internal virtual {
        if (hasFee) {
            uint256 toUrn = (amount * urnFee) / DENOMINATOR;
            uint256 toDev = (amount * devFee) / DENOMINATOR;
            uint256 lessTax = amount - (toUrn + toDev);

            super._mint(to, lessTax);
            super._mint(urn, toUrn);
            super._mint(dev, toDev);
        } else {
            super._mint(to, amount);
        }
    }

    function sweep() public onlyUrn {
        uint256 _token = merge.tokenOf(address(this));
        require(_token > 0, "nothing to sweep");

        uint256 _mass = merge.massOf(_token);

        // merge .mass with alpha
        merge.transferFrom(address(this), vault, _token);

        // mint .alpha
        _mint(urn, _mass * 1e18, false);
    }

    function onERC721Received(
        address _operator,
        address from,
        uint256 _tokenId,
        bytes calldata _data
    ) public virtual override whenNotPaused returns (bytes4) {
        // verify only merge tokens are sent
        require(msg.sender == address(merge), "only send merge");

        // winning .merge token
        uint256 _token = merge.tokenOf(address(this));

        // check if merge is allowed
        uint256 _mass = merge.massOf(_token);
        require(_mass <= maxMass, "mass higher than allowed");

        // merge .mass with alpha
        merge.transferFrom(address(this), vault, _token);

        // mint .alpha
        _mint(from, _mass * 1e18, true);

        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address _operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata _data
    ) public virtual whenNotPaused returns (bytes4) {
        // verify only genesis tokens are sent
        require(msg.sender == address(genesis), "only send genesis");
        require(id == uint256(1), "only send interns");

        // burn The Internship token
        genesis.safeTransferFrom(address(this), address(0xdEaD), id, value, "");
        require(genesis.balanceOf(address(this), id) == 0, "burn failed");

        uint256 _alpha = value * INTERN_VALUE;

        // mint .alpha
        _mint(from, _alpha, false);

        return IERC1155Receiver.onERC1155Received.selector;
    }
}