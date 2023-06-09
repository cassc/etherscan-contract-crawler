// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal proxy library
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title OasisX NFT Launch Factory
 * @notice NFT Lauch Factory contract
 * @author OasisX Protocol | cryptoware.eth
 **/

/// @dev an interface to interact with the NFT721 base contract
interface IOasisXNFT721 {
    function initialize(
        bytes memory data,
        address owner_,
        uint256 protocolFee_,
        address protocolAddress_
    ) external;
}

/// @dev an interface to interact with the NFT1155 base contract
interface IOasisXNFT1155 {
    function initialize(
        bytes memory data,
        address owner_,
        uint256 protocolFee_,
        address protocolAddress_
    ) external;
}

interface IOasisXEntry {
    function getMaxId() external returns (uint8);

    function balanceOf(address account, uint256 id) external returns (uint256);

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

}

contract OasisXLaunchFactory is Ownable, ReentrancyGuard {
    /// @notice cheaply clone contract functionality in an immutable way
    using Clones for address;

    /// @notice Base ERC721 address
    address public NFT721Base;

    /// @notice Base ERC1155 address
    address public NFT1155Base;

    /// @notice Address of protocol fee wallet;
    address payable public protocolAddress;

    address public OasisXNFTEntryAddress;

    /// @notice Access fee to charge per clone type
    mapping(uint256 => uint256) public accessFee;

    /// @notice protocol fees from every drop
    uint256 public protocolFee;

    /// @notice Payable clone
    bool public payableEntry;

    /// @notice 721 contracts mapped by owner address
    mapping(address => address[]) public clones721;

    /// @notice 1155 contracts mapped by owner address
    mapping(address => address[]) public clones1155;

    /// @notice Cloning events definition
    event New721Clone
    (
        address indexed _newClone,
        address indexed _owner
    );

    event New1155Clone
    (
        address indexed _newClone,
        address indexed _owner
    );

    event cloneAccessChanged();

    event AccessFeeChanged
    (
        uint256[] indexed cloneTypes,
        uint256[] indexed amount
    );

    event ProtocolFeeChanged
    (
        uint256 indexed protocolFee
    );

    event ProtocolAddressChanged
    (
        address indexed protocol
    );

    event Implementation721Changed
    (
        address indexed Base721
    );

    event Implementation1155Changed
    (
        address indexed Base1155
    );

   event OasisXNFTEntryAddressChanged(address indexed newAddress);

    receive() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    fallback() external payable {
        revert("OasisXNFT721: Please use Mint or Admin calls");
    }

    /**
     * @notice constructor
     * @param BaseNFT721 address of the Base 721 contract to be cloned
     * @param BaseNFT1155 address of the Base 1155 contract to be cloned
     * @param protocolFee_ fee for the protocol
     * @param _protocolAddress protocol address to collect mint fees
     * @param _OasisXEntry 1155Entry address to access the clone factory

     **/
    constructor(
        address BaseNFT721,
        address BaseNFT1155,
        uint256 protocolFee_,
        address _protocolAddress,
        address _OasisXEntry
    ) {
        require
        (
            BaseNFT721 != address(0),
            "OasisXLaunchFactory: BaseNFT721 address cannot be 0"
        );
        require
        (
   
            BaseNFT1155 != address(0) ,
            "OasisXLaunchFactory: BaseNFT1155 address cannot be 0"
        );
        require
        (

            _protocolAddress != address(0) ,
            "OasisXLaunchFactory: _protocolAddress address cannot be 0"
        );
        require
        (

            _OasisXEntry != address(0),
            "OasisXLaunchFactory: _OasisXEntry address cannot be 0"
        );
        NFT721Base = BaseNFT721;
        NFT1155Base = BaseNFT1155;
        protocolFee = protocolFee_;
        protocolAddress = payable(_protocolAddress);
        OasisXNFTEntryAddress = _OasisXEntry;
    }

    /**
     * @notice initializing the cloned contract
     * @param data Represent the 1155Proxy params encoded
     **/
    function create1155(bytes memory data) external payable nonReentrant {
        require(
            holderAndBurnOrPayable(0, msg.value),
            "OasisXNFT1155 : Not OasisX nft holder or Eth sent mismatch"
        );

        address identicalChild = NFT1155Base.clone();

        clones1155[msg.sender].push(identicalChild);

        IOasisXNFT1155(identicalChild).initialize(
            data,
            msg.sender,
            protocolFee,
            protocolAddress
        );

        emit New1155Clone(identicalChild, msg.sender);
    }

    /**
     * @notice initializing the cloned contract
     * @param data Represent the 721Proxy params encoded
     **/
    function create721(bytes memory data) external payable nonReentrant {
        require(
            holderAndBurnOrPayable(1, msg.value),
            "OasisXNFT721 : Not OasisX nft holder or Eth sent mismatch"
        );

        address identicalChild = NFT721Base.clone();

        clones721[msg.sender].push(identicalChild);

        IOasisXNFT721(identicalChild).initialize(
            data,
            msg.sender,
            protocolFee,
            protocolAddress
        );

        emit New721Clone(identicalChild, msg.sender);
    }

    /**
     * @notice Change clone from OasisXNFTEntry to payable and vis verca
     **/
    function changeCloneAccess() external onlyOwner {
        payableEntry = !payableEntry;
        emit cloneAccessChanged();
    }

    /**
     * @notice assert msg.value equal accessFee or msg.sender hold OasisXNFTEntry and burn
     * @param cloneType type of clone
     * @param amount amount of new access fee
     */
    function holderAndBurnOrPayable(uint256 cloneType, uint256 amount)
        internal
        returns (bool)
    {
        if (payableEntry && amount > 0) {
            if (amount == accessFee[cloneType]) {
                (bool success, ) = protocolAddress.call{
                    value: amount,
                    gas: 2800
                }("");
                return success;
            }
            return false;
        } else if (!payableEntry && amount == 0) {
            uint8 maxEntries = IOasisXEntry(OasisXNFTEntryAddress).getMaxId();

            for (uint256 i = cloneType; i <= maxEntries; i++) {
                if (
                    IOasisXEntry(OasisXNFTEntryAddress).balanceOf(
                        msg.sender,
                        i
                    ) >
                    0 &&
                    cloneType == 0
                ) {
                    return true;
                } else if (
                    IOasisXEntry(OasisXNFTEntryAddress).balanceOf(
                        msg.sender,
                        i
                    ) >
                    0 &&
                    cloneType == 1
                ) {
                    if (i == 1) {
                        
                        IOasisXEntry(OasisXNFTEntryAddress).burn(
                            msg.sender,
                            1,
                            1
                        );
                        return true;
                    } else {
                        return true;
                    }
                }
            }
            return false;
        }
        return false;
    }

    /**
     * @notice change launchpad access fee if payable option
     * @param cloneType clone type wether 721 or 1155
     * @param amount protocol fee
     */
    function changeAccessFee(
        uint256[] memory cloneType,
        uint256[] memory amount
    ) external onlyOwner {
        require(
            cloneType.length == amount.length,
            "OasisXLaunchFactory: New access fee cannot be the same"
        );

        for (uint256 i = 0; i < cloneType.length; i++) {
            accessFee[cloneType[i]] = amount[i];
        }
        emit AccessFeeChanged(cloneType, amount);
    }

    /**
     * @notice Owner can change protocol fee
     * @param amount amount of new protocol fee
     */
    function changeProtocolFee(uint256 amount) external onlyOwner {
        require(
            amount != protocolFee,
            "OasisXLaunchFactory: New Protocol fee cannot be the same"
        );
        protocolFee = amount;
        emit ProtocolFeeChanged(amount);
    }

    /**
     * @notice Owner can change protocol address
     * @param addr address of new protocol
     */
    function changeProtocolAddress(address addr) external onlyOwner {
        require(
            addr != address(0),
            "OasisXLaunchFactory: New Protocol cannot be address 0"
        );
        require(
            addr != protocolAddress,
            "OasisXLaunchFactory: New Protocol cannot be address 0"
        );
        protocolAddress = payable(addr);
        emit ProtocolAddressChanged(addr);
    }

    /**
     * @notice Change 721 Base Contract
     * @param new_add address of new 721 Base contract
     */
    function change721Implementation(address new_add) external onlyOwner {
        require(
            new_add != address(0),
            "OasisXLaunchFactory: New 721 Base cannot be address 0"
        );
        require(
            new_add != NFT721Base,
            "OasisXLaunchFactory: New 721 Base address is the same"
        );
        NFT721Base = new_add;
        emit Implementation721Changed(new_add);
    }

    /**
     * @notice Change 1155 Base Contract
     * @param new_add address of new 1155 Base Contract
     */
    function change1155Implementation(address new_add) external onlyOwner {
        require(
            new_add != address(0),
            "OasisXLaunchFactory: New 1155 Base cannot be address 0"
        );
        require(
            new_add != NFT1155Base,
            "OasisXLaunchFactory: New 1155 Base address cannot be the same"
        );
        NFT1155Base = new_add;
        emit Implementation1155Changed(new_add);
    }

    function changeOasisXNFTEntryAddress(address new_add) external onlyOwner {
        require
        (
            new_add != address(0),
            "OasisXLaunchFactory: Address cannot be 0"
        );

        require
        (
            new_add != OasisXNFTEntryAddress,
            "OasisXLaunchFactory: Address cannot be same as previous"
        );

        OasisXNFTEntryAddress = new_add;
        emit OasisXNFTEntryAddressChanged(new_add);
    }
}