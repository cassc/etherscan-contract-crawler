// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTTricket is ERC721("BABY-TRICKET", "BABY-TRICKET"), Ownable {
    string private _tokenName;

    string private _tokenSymbol;

    // Whether it is initialized
    bool public isInitialized;
    // The address of the smart chef factory
    address public SMART_TICKE_FACTORY;
    bool public canTransfer;
    mapping(address => bool) public _isExcludedFrom;
    mapping(address => bool) public _isExcludedTo;

    constructor() {
        SMART_TICKE_FACTORY = _msgSender();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address _owner
    ) public {
        require(!isInitialized, "Already initialized");
        require(msg.sender == SMART_TICKE_FACTORY, "Not the  factory ");
        // Make this contract initialized
        isInitialized = true;

        _tokenName = name_;
        _tokenSymbol = symbol_;
        _isExcludedFrom[address(0)] = true;
        transferOwnership(_owner);
    }

    function switchTransfer(bool onOff) external onlyOwner {
        canTransfer = onOff;
    }

    function excludeFrom(address account) external onlyOwner {
        _isExcludedFrom[account] = true;
    }

    function includeInFrom(address account) external onlyOwner {
        _isExcludedFrom[account] = false;
    }

    function excludeTo(address account) external onlyOwner {
        _isExcludedTo[account] = true;
    }

    function includeInTo(address account) external onlyOwner {
        _isExcludedTo[account] = false;
    }

    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    function mint(address to, uint256 tokenId) external {
        require(
            _msgSender() == SMART_TICKE_FACTORY,
            "NFTTicket: No permission"
        );
        _mint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 
    ) internal virtual override {
        require(
            canTransfer || _isExcludedFrom[from] || _isExcludedTo[to],
            "NFTTicket: transfer prohibited"
        );
    }
}

contract INO is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct INOInfo {
        uint256 id;
        uint256 totalSupply;
        uint256 hardcapPerUser;
        address nftTicket;
        uint256 uintPrice;
        uint256 supplied;
        address payable recipient;
        address currency;
        uint256 startTime;
        uint256 duration;
        address vault;
        mapping(address => uint256) mintQuantity;
    }

    uint256 public inoIds;
    mapping(uint256 => INOInfo) public inoInfos;

    event Mint(uint256 id, address account, uint256 number);

    function mintQuantity(uint256 id, address account)
        public
        view
        returns (uint256)
    {
        return inoInfos[id].mintQuantity[account];
    }

    function createINO(
        uint256 totalSupply,
        uint256 hardcapPerUser,
        uint256 uintPrice,
        address currency,
        address vault,
        address payable recipient,
        address nftTicket,
        uint256 startTime,
        uint256 duration,
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (nftTicket == address(0) || vault == address(0)) {
            require(nftTicket == vault, "INO: Vault cannot be set up");
        }
        inoIds += 1;
        inoInfos[inoIds].id = inoIds;
        inoInfos[inoIds].totalSupply = totalSupply;
        inoInfos[inoIds].hardcapPerUser = hardcapPerUser;
        inoInfos[inoIds].uintPrice = uintPrice;
        inoInfos[inoIds].recipient = recipient;
        inoInfos[inoIds].currency = currency;
        inoInfos[inoIds].startTime = startTime;
        inoInfos[inoIds].duration = duration;

        address nftTicketAddress;
        if (nftTicket == address(0)) {
            bytes memory bytecode = type(NFTTricket).creationCode;
            bytes32 salt = keccak256(abi.encodePacked(inoIds));
            assembly {
                nftTicketAddress := create2(
                    0,
                    add(bytecode, 32),
                    mload(bytecode),
                    salt
                )
            }
            NFTTricket(nftTicketAddress).initialize(name, symbol, msg.sender);
        } else {
            inoInfos[inoIds].vault = vault;
            nftTicketAddress = nftTicket;
        }

        inoInfos[inoIds].nftTicket = nftTicketAddress;
    }

    function mint(uint256 id, uint256 number) external payable {
        INOInfo storage inoInfo = inoInfos[id];
        require(
            inoInfo.supplied.add(number) <= inoInfo.totalSupply,
            "INO: insufficient supply"
        );
        require(block.timestamp >= inoInfo.startTime, "INO: has not started");
        require(
            block.timestamp < inoInfo.startTime.add(inoInfo.duration),
            "INO: ino is over"
        );
        require(
            inoInfo.mintQuantity[_msgSender()].add(number) <=
                inoInfo.hardcapPerUser,
            "INO: Exceed the purchase limit"
        );
        inoInfo.mintQuantity[_msgSender()] = inoInfo
            .mintQuantity[_msgSender()]
            .add(number);

        if (inoInfo.currency == address(0)) {
            require(
                msg.value == number.mul(inoInfo.uintPrice),
                "INO: wrong payment amount"
            );
            inoInfo.recipient.transfer(msg.value);
        } else {
            IERC20(inoInfo.currency).safeTransferFrom(
                _msgSender(),
                inoInfo.recipient,
                number.mul(inoInfo.uintPrice)
            );
        }
        for (uint256 i = 0; i != number; i++) {
            inoInfo.supplied = inoInfo.supplied.add(1);
            if (inoInfo.vault == address(0)) {
                NFTTricket(inoInfo.nftTicket).mint(
                    _msgSender(),
                    inoInfo.supplied
                );
            } else {
                mintForVault(
                    inoInfo.vault,
                    _msgSender(),
                    ERC721(inoInfo.nftTicket)
                );
            }
        }

        emit Mint(id, _msgSender(), number);
    }

    function mintForVault(
        address vault,
        address to,
        ERC721 nftAddress
    ) internal {
        uint256 balance = nftAddress.balanceOf(vault);
        require(balance > 0, "INO: Insufficient balance in the vault");
        uint256 idx = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, balance)
            )
        ) % balance;
        uint256 tokenId = nftAddress.tokenOfOwnerByIndex(vault, idx);
        nftAddress.transferFrom(vault, to, tokenId);
    }
}