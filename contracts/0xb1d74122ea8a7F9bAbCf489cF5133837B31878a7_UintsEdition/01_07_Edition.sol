/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                             ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░                             ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utilities.sol";

interface IUints {
    function getValue(uint id) external view returns (uint);
    function ownerOf(uint id) external view returns (address);
    function balanceOf(address owner) external view returns (uint);
}

interface IChanges {
    function mint(
        uint counter,
        uint position,
        string memory color,
        address artist,
        uint uintsId,
        uint timestamp
    ) external;
}

/// @title UINTS Edition
/// @author Parker Thompson
/// @notice This contract handles minting and changing UINTS Edition art
contract UintsEdition is ERC721A, Ownable {
    constructor() ERC721A("UINTS Edition", "UE") {}

    uint64 public startMintTime = 1683201600;         // 5/4/23 12:00:00 UTC
    uint64 public stopPrivateMintTime = 1683288000;  //  5/5/23 12:00:00 UTC
    uint64 public stopPublicMintTime = 1683374400;  //   5/6/23 12:00:00 UTC
    uint public publicMintCost = 2000000000000000; //    WEI --> 0.002 ETH
    uint public changeCounter;

    mapping(address => uint) public privateMinted;
    mapping(uint => uint32) public colors;

    address _uintsContract = 0x7C10C8816575e8Fdfb11463dD3811Cc794A1D407;
    address _changesContract;

    event artChanged(
        address indexed artist,
        uint changeCount,
        uint position,
        uint8[3] rgbColors,
        uint uintsId,
        uint timestamp
    );

    /// @notice Set the UINTS Changes contract address
    function setChangesContract(address contractAddress) public onlyOwner {
        _changesContract = contractAddress;
        iChangesContract = IChanges(contractAddress);
    }

    IUints iUintsContract = IUints(_uintsContract);
    IChanges iChangesContract = IChanges(_changesContract);

    /// @notice Mint a UINTS Edition
    /// @dev Minting requirements are based on minting window
    function mint(uint quantity) public payable {
        if (block.timestamp < stopPrivateMintTime) {
            // free claim window for UINTS holders
            require(block.timestamp >= startMintTime, "Minting has not started");
            require(quantity <= 3 - privateMinted[msg.sender], "Exceeds max free mints");
            require(iUintsContract.balanceOf(msg.sender) > 0, "Must own at least 1 UINTS");

            // subtract 3 seconds from public mint window for each token
            // "stop the mint bro"
            stopPublicMintTime -= uint64(quantity * 3);
            privateMinted[msg.sender] += quantity;
        } else {
            // public mint window
            require(block.timestamp < stopPublicMintTime, "Mint has closed");
            require(msg.value >= quantity * publicMintCost, "Not enough eth");
        }
        batchMint(quantity);
    }

    /// @dev Batch minting is optimized for ERC721A
    /// @param quantity Number of tokens to mint
    function batchMint(uint quantity) internal {
        if (quantity > 30) {
            uint fullRuns = quantity / 30;
            uint remainder = quantity % 30;
            for (uint i = 0; i < fullRuns; i++) {
                _mint(msg.sender, 30);
            }
            if (remainder > 0) {
                _mint(msg.sender, remainder);
            }
        } else {
            _mint(msg.sender, quantity);
        }
    }

    /// @notice Change the color of one of the UINTS Edition squares
    /// @param position Square to be updated (1-64)
    /// @param rgbColors RGB colors to use (i.e. red = [255,0,0])
    /// @param uintsId ID of UINTS token to be used
    function changeColor(
        uint position,
        uint8[3] memory rgbColors,
        uint uintsId
    ) public {
        uint tokenValue = iUintsContract.getValue(uintsId);
        require(position > 0 && position < 65, "Position out of range");
        require(
            iUintsContract.ownerOf(uintsId) == msg.sender,
            "UINTS not owned"
        );
        require(tokenValue >= getMinimumValue(), "UINTS value is too low");
        require(balanceOf(msg.sender) > 0, "Must own at least 1 UINTS Edition");

        uint32 colorValue = (uint32(rgbColors[0]) << 16) |
            (uint32(rgbColors[1]) << 8) |
            uint32(rgbColors[2]);

        colors[position] = colorValue;

        // your receipt is in the bag
        iChangesContract.mint(
            changeCounter + 1,
            position,
            utils.uint32ToString(colorValue),
            msg.sender,
            uintsId,
            block.timestamp
        );

        emit artChanged(msg.sender, changeCounter + 1, position, rgbColors, uintsId, block.timestamp);

        changeCounter++;
    }

    /// @notice Gets the current list of colors for the artwork
    function getCurrentColors()
        public
        view
        returns (uint32[64] memory colorArray)
    {
        for (uint i = 1; i < 65; i++) {
            colorArray[i - 1] = colors[i];
        }
    }

    /// @notice Gets the current minimum UINTS value needed to change Edition art
    /// @dev The minimum value increases over time until it reaches 9999
    function getMinimumValue() public view returns (uint) {
      uint daysElapsed = (block.timestamp - startMintTime) / 86400;
      if (daysElapsed <= 310) {
          uint multiplier = (daysElapsed / 10) + 1;
          return daysElapsed * multiplier;
      } else {
          return 9999;
      }
    }

    function b64Svg() public view returns (string memory) {
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(utils.renderSvg(getCurrentColors())))));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory result) {
        string memory json = string(
            abi.encodePacked(
                '{"name": "UINTS Edition ',
                _toString(tokenId),
                '", "description": "UINTS Edition art is updated on-chain by UINTS holders.", "image": "',
                b64Svg(),
                '"}'
            )
        );

        result = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Withdraw all contract funds
    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}