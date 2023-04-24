// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IOKPassTransfer.sol";
import "./Soulbound.sol";

contract OKPassTransfer is IOKPassTransfer, Ownable, Soulbound {
    address public passAddress = 0xb314Ce89113494D8B324e8C3240D9cb23f5406a3;

    struct BridgeEvent {
        uint256 timestamp;
        string ordAddress;
    }

    mapping(uint256 => BridgeEvent) public departures;

    string public contractURIString;
    string public tokenImageString =
        "https://northupcrypto.mypinata.cloud/ipfs/QmUvviPmiNysAhjqgLtRwpRZPx81c2ewaHJEFenXkApjjW";
    string public tokenDescription =
        "Ordinal Kitten Used Passes are a soulbound token obtained after claiming an Ordinal Kitten";

    constructor() ERC721("Ordinal Kittens Used Pass", "OKUP") {}

    //////// Public functions

    event TransferToBTC(uint256 indexed id, string ordAddress);

    function transferOrdinal(
        uint256 id,
        address burnerAddress,
        string memory ordAddress
    ) external override returns (bool) {
        // Must come from OKP contract
        require(msg.sender == passAddress);

        // Give SBT for on-eth tracking
        _mint(burnerAddress, id);

        // Transfer
        emit TransferToBTC(id, ordAddress);
        departures[id] = BridgeEvent(block.timestamp, ordAddress);
        return true;
    }

    function getTokenOrdAddress(
        uint256 id
    ) external view returns (string memory) {
        return departures[id].ordAddress;
    }

    function getTokenTimestamp(uint256 id) external view returns (uint256) {
        return departures[id].timestamp;
    }

    function contractURI() public view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    contractURIString
                )
            )
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        return (
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "Ordinal Kitten Used Pass #',
                                Strings.toString(tokenId),
                                '", "description": "',
                                tokenDescription,
                                '", "image": "',
                                tokenImageString,
                                '"}'
                            )
                        )
                    )
                )
            )
        );
    }

    //////// Owner functions
    function setPassAddress(address _passAddress) external onlyOwner {
        passAddress = _passAddress;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURIString = _contractURI;
    }

    function setTokenImageString(
        string memory _tokenImageString
    ) external onlyOwner {
        tokenImageString = _tokenImageString;
    }

    function setTokenDescription(
        string memory _tokenDescription
    ) external onlyOwner {
        tokenDescription = _tokenDescription;
    }
}