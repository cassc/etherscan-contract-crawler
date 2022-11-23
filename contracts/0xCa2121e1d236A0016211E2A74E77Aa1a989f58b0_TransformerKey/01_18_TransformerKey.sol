// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IStreetMachineGenesis {
    function burnAndMint(
        uint256 tokenId,
        uint256 typeOption,
        uint256 transformerKeyTokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getKeyAllowListCount(address minter)
        external
        view
        returns (uint256 amount);
}

interface IRevealContract is IERC721 {
    function transferOwnership(address newOwner) external;

    function emergencySetCid(uint256 tokenId, string memory cid) external;

    function setCids(string[] memory _cids) external;

    function flipRevealActive() external;

    function setBaseURI(string memory baseUri) external;

    function setBaseCID(string memory baseCid) external;
}

contract TransformerKey is ERC721AQueryable, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public maxSupply = 8000;
    string public baseURI = "";

    mapping(address => uint256) public addressToClaimedCount;

    IRevealContract public revealContract;
    IStreetMachineGenesis public pfpContract;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _revealContractAddress,
        address _genesisContractAddress
    ) ERC721A(_tokenName, _tokenSymbol) {
        revealContract = IRevealContract(_revealContractAddress);
        pfpContract = IStreetMachineGenesis(_genesisContractAddress);
    }

    address public signingAddress;

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _url) public onlyOwner {
        baseURI = _url;
    }

    function emergencySetRevealCid(uint256 tokenId, string memory cid)
        public
        onlyOwner
    {
        revealContract.emergencySetCid(tokenId, cid);
    }

    function emergencySetRevealCids(string[] memory _cids) public onlyOwner {
        revealContract.setCids(_cids);
    }

    function emergencySetRevealBaseURI(string memory baseUri) public onlyOwner {
        revealContract.setBaseURI(baseUri);
    }

    function emergencySetRevealBaseCID(string memory baseCid) public onlyOwner {
        revealContract.setBaseCID(baseCid);
    }

    function flipRevealActive() public onlyOwner {
        revealContract.flipRevealActive();
    }

    function transferRevealOwnership(address newOwner) public onlyOwner {
        revealContract.transferOwnership(newOwner);
    }

    function setSigningAddress(address _signingAddress) public onlyOwner {
        signingAddress = _signingAddress;
    }

    function _validateServerSignedMessage(
        bytes32 message,
        bytes calldata signature,
        uint256 tokenId,
        uint256 typeOption,
        string memory cid
    ) internal virtual {
        uint256 resultingTokenId;
        uint256 additionalLength;

        if (typeOption == 0) {
            resultingTokenId = tokenId + 8000; // females

            if (resultingTokenId < 10000) {
                additionalLength = 3; // 8000-9999
            } else {
                additionalLength = 4; // 10000-15999
            }
        } else {
            require(typeOption == 1, "invalid typeOption");

            resultingTokenId = tokenId + 16000; // other
            additionalLength = 4; // 16000-23999
        }

        address signer = message.recover(signature);
        require(signer == signingAddress, "Invalid signature");

        // cids must all be the same length
        bytes32 expectedMessage = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString((61 + additionalLength)),
                Strings.toString(resultingTokenId),
                "-",
                cid
            )
        );
        require(message == expectedMessage, "Malformed message");
    }

    function burnAndReroll(
        uint256 tokenId,
        bytes32 message,
        bytes calldata signature,
        uint256 typeOption,
        string memory cid,
        uint256 pfpTokenId
    ) public returns (bool) {
        require(
            tx.origin == ownerOf(tokenId),
            "must be initiated by token owner"
        );
        _validateServerSignedMessage(
            message,
            signature,
            tokenId,
            typeOption,
            cid
        );

        uint256 resultingTokenId;

        if (typeOption == 0) {
            resultingTokenId = tokenId + 8000; // females
        } else {
            require(typeOption == 1, "invalid typeOption");
            resultingTokenId = tokenId + 16000; // other
        }

        revealContract.emergencySetCid(resultingTokenId, cid);
        pfpContract.burnAndMint(pfpTokenId, typeOption, tokenId);
        _burn(tokenId);

        return true;
    }

    function claimAll() public returns (uint256) {
        uint256 totalClaimable = pfpContract.getKeyAllowListCount(msg.sender);

        for (
            uint256 i = addressToClaimedCount[msg.sender];
            i < totalClaimable;
            i++
        ) {
            mint();
        }

        return totalSupply();
    }

    function mint() public returns (uint256) {
        require(totalSupply() + 1 <= maxSupply, "Exceeds max supply");
        require(
            addressToClaimedCount[msg.sender] <
                pfpContract.getKeyAllowListCount(msg.sender),
            "claimed count must be less than allowance"
        );

        _safeMint(msg.sender, 1);

        addressToClaimedCount[msg.sender] += 1;

        return totalSupply();
    }
}