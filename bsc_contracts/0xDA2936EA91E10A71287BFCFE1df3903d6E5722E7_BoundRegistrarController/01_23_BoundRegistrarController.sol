// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IRegistrar.sol";
import "../interfaces/IBoundRegistrarController.sol";
import "../libraries/Registration.sol";
import "../libraries/SignatureChecker.sol";
import "../libraries/StringUtils.sol";

/**
 * @dev A bound registrar controller for registering and renewing names at fixed cost, supporting multiple tlds.
 */
contract BoundRegistrarController is
    Ownable,
    ReentrancyGuard,
    EIP712,
    IBoundRegistrarController
{
    using Address for address;
    using SafeERC20 for IERC20;
    using StringUtils for *;
    using Registration for Registration.RegisterOrder;

    address public constant NATIVE_TOKEN_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // 365.2425 days
    uint256 public constant MIN_REGISTRATION_DURATION = 31556952;

    // A commitment can only be revealed after the minimum commitment age.
    uint256 public minCommitmentAge;
    // A commitment expires after the maximum commitment age.
    uint256 public maxCommitmentAge;

    IRegistry public immutable registry;

    constructor(
        uint256 _minCommitmentAge,
        uint256 _maxCommitmentAge,
        IRegistry _registry
    ) EIP712("RegistrarController", "1") ReentrancyGuard() {
        require(_maxCommitmentAge > _minCommitmentAge);
        minCommitmentAge = _minCommitmentAge;
        maxCommitmentAge = _maxCommitmentAge;

        registry = _registry;
    }

    function rentPrice(
        address registrar,
        string memory name,
        uint256 duration
    ) public view override returns (IPriceOracle.Price memory price) {
        bytes32 label = keccak256(bytes(name));

        IRegistrar r = IRegistrar(registrar);
        price = IPriceOracle(r.priceOracle()).price(
            name,
            r.nameExpires(uint256(label)),
            duration
        );
    }

    function valid(string memory name) public pure returns (bool) {
        bytes memory bname = bytes(name);
        // zero width for /u200b /u200c /u200d and U+FEFF
        for (uint256 i; i < bname.length - 2; i++) {
            if (bytes1(bname[i]) == 0xe2 && bytes1(bname[i + 1]) == 0x80) {
                if (
                    bytes1(bname[i + 2]) == 0x8b ||
                    bytes1(bname[i + 2]) == 0x8c ||
                    bytes1(bname[i + 2]) == 0x8d
                ) {
                    return false;
                }
            } else if (bytes1(bname[i]) == 0xef) {
                if (
                    bytes1(bname[i + 1]) == 0xbb && bytes1(bname[i + 2]) == 0xbf
                ) return false;
            }
        }
        return true;
    }

    function available(address registrar, string memory name)
        public
        view
        override
        returns (bool)
    {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && IRegistrar(registrar).available(uint256(label));
    }

    function nameExpires(address registrar, string memory name)
        public
        view
        override
        returns (uint256)
    {
        bytes32 label = keccak256(bytes(name));
        return IRegistrar(registrar).nameExpires(uint256(label));
    }

    function register(Registration.RegisterOrder calldata order)
        public
        payable
        override
        nonReentrant
    {
        IPriceOracle.Price memory price = _checkRegister(order);
        IRegistrar registrar = IRegistrar(order.registrar);

        uint256 cost = price.base + price.premium;
        IERC20(price.currency).safeTransferFrom(
            msg.sender,
            address(this),
            cost
        );
        IERC20(price.currency).safeTransfer(registrar.feeRecipient(), cost);

        string memory name = string(order.name);
        (uint256 tokenId, uint256 expires) = registrar.register(
            name,
            order.owner,
            order.duration,
            order.resolver
        );

        emit NameRegistered(
            order.registrar,
            keccak256(order.name),
            name,
            order.owner,
            tokenId,
            price.base + price.premium,
            expires
        );
    }

    function registerWithETH(Registration.RegisterOrder calldata order)
        public
        payable
        override
        nonReentrant
    {
        IPriceOracle.Price memory price = _checkRegister(order);
        IRegistrar registrar = IRegistrar(order.registrar);

        require(
            price.currency == NATIVE_TOKEN_ADDRESS,
            "RegistrarController: invalid currency"
        );
        require(
            order.currency == NATIVE_TOKEN_ADDRESS,
            "RegistrarController: invalid payment token"
        );
        uint256 cost = price.base + price.premium;
        require(
            msg.value >= cost,
            "RegistrarController: Not enough funds provided"
        );
        registrar.feeRecipient().transfer(cost);

        string memory name = string(order.name);
        (uint256 tokenId, uint256 expires) = registrar.register(
            name,
            order.owner,
            order.duration,
            order.resolver
        );

        emit NameRegistered(
            order.registrar,
            keccak256(order.name),
            name,
            order.owner,
            tokenId,
            price.base + price.premium,
            expires
        );

        _returnDust();
    }

    function bulkRegister(Registration.RegisterOrder[] calldata orders)
        external
        payable
        override
    {
        for (uint256 i = 0; i < orders.length; i++) {
            address(this).delegatecall(
                abi.encodeWithSelector(
                    IBoundRegistrarController.register.selector,
                    orders[i]
                )
            );
        }
    }

    function renew(
        address registrar,
        string calldata name,
        uint256 duration
    ) public payable override nonReentrant {
        bytes32 label = keccak256(bytes(name));
        IPriceOracle.Price memory price = rentPrice(registrar, name, duration);
        IRegistrar r = IRegistrar(registrar);

        _transferFee(msg.sender, r, price);
        uint256 tokenId;
        uint256 expires;
        (tokenId, expires) = r.renew(uint256(label), duration);

        emit NameRenewed(
            registrar,
            label,
            name,
            tokenId,
            price.base + price.premium,
            expires
        );
    }

    function changeCommitmentAge(uint256 min, uint256 max) external onlyOwner {
        minCommitmentAge = min;
        maxCommitmentAge = max;
    }

    function withdraw(address payable to, uint256 amount) external onlyOwner {
        Address.sendValue(to, amount);
    }

    function withdrawERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IBoundRegistrarController).interfaceId;
    }

    /* Internal functions */

    function _checkRegister(Registration.RegisterOrder calldata order)
        internal
        view
        returns (IPriceOracle.Price memory)
    {
        IRegistrar registrar = IRegistrar(order.registrar);
        // Check the register order
        bytes32 registerHash = order.hash();
        _validateOrder(order, registrar, registerHash);

        IPriceOracle.Price memory price = rentPrice(
            order.registrar,
            string(order.name),
            order.duration
        );
        return price;
    }

    function _transferFee(
        address from,
        IRegistrar registrar,
        IPriceOracle.Price memory price
    ) internal {
        uint256 cost = price.base + price.premium;
        if (price.currency == NATIVE_TOKEN_ADDRESS) {
            require(
                msg.value >= cost,
                "RegistrarController: Not enough funds provided"
            );

            registrar.feeRecipient().transfer(cost);
        } else {
            IERC20(price.currency).safeTransferFrom(from, address(this), cost);
            IERC20(price.currency).safeTransfer(registrar.feeRecipient(), cost);
        }
    }

    function _validateOrder(
        Registration.RegisterOrder calldata order,
        IRegistrar registrar,
        bytes32 registerHash
    ) internal view {
        // Require a valid registration (is old enough and is committed)
        require(
            order.applyingTime + minCommitmentAge <= block.timestamp,
            "RegistrarController: Registration is not valid"
        );

        // If the registration is too old, or the name is registered, stop
        require(
            order.applyingTime + maxCommitmentAge > block.timestamp,
            "RegistrarController: Registration has expired"
        );
        require(
            available(address(registrar), string(order.name)),
            "RegistrarController: Name is unavailable"
        );

        require(order.duration >= MIN_REGISTRATION_DURATION);

        // Verify the signer is not address(0)
        require(
            order.issuer != address(0) && order.issuer == registrar.issuer(),
            "RegistrarController: Invalid issuer"
        );

        require(
            order.currency == IPriceOracle(registrar.priceOracle()).currency(),
            "RegistrarController: Invalid currency"
        );

        // Verify the validity of the signature
        require(
            SignatureChecker.verify(
                registerHash,
                order.issuer,
                order.v,
                order.r,
                order.s,
                _domainSeparatorV4()
            ),
            "Signature: Invalid"
        );
    }

    function _returnDust() internal {
        // return remaining native token (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                    gas(),
                    caller(),
                    selfbalance(),
                    0,
                    0,
                    0,
                    0
                )
            }
        }
    }
}