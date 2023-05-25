// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract RickhouseDAO is ERC1155, ERC2981, Ownable {
    uint256 numTokens = 0;
    mapping(uint256 => Token) public tokens;
    address public proxyRegistryAddress;
    address public developer;
    address public royaltyRecipient;
    string public docs;
    string public name;
    string public symbol;

    struct Token {
        uint256 publicPrice;
        uint256 publicAllowance;
        uint256 allowlistPrice;
        uint256 allowlistAllowance;
        uint256 totalSupply;
        uint256 minted;
        uint256 startTime;
        uint256 endTime;
        uint256 allowlistDuration;
        string uri;
        bytes32 merkleRoot;
        mapping(address => uint256) addressToMinted;
    }

    constructor(
        address _developer,
        address _proxyRegistryAddress,
        address payable _royaltyReceiver,
        string memory _name,
        string memory _symbol,
        string memory _docs
    ) ERC1155("") {
        developer = _developer;
        proxyRegistryAddress = _proxyRegistryAddress;
        docs = _docs;
        name = _name;
        symbol = _symbol;
        _setDefaultRoyalty(_royaltyReceiver, 1000);
    }

    function _leaf(string memory tokenId, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, tokenId));
    }

    function allowlistMint(
        uint256 tokenId,
        uint256 count,
        bytes32[] calldata proof
    ) external payable {
        require(tokenId <= numTokens, "invalid token id");

        string memory payload = string(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(
                proof,
                tokens[tokenId].merkleRoot,
                _leaf(Strings.toString(tokenId), payload)
            ),
            "invalid proof"
        );
        require(
            block.timestamp > tokens[tokenId].startTime &&
                block.timestamp <
                tokens[tokenId].startTime + tokens[tokenId].allowlistDuration,
            "token not active"
        );
        if (tokens[tokenId].allowlistAllowance > 0) {
            require(
                tokens[tokenId].addressToMinted[msg.sender] + count <=
                    tokens[tokenId].allowlistAllowance,
                "exceeds allowlist allowance"
            );
        }
        if (tokens[tokenId].totalSupply > 0) {
            require(
                tokens[tokenId].minted + count <= tokens[tokenId].totalSupply,
                "exceeds total supply"
            );
        }
        require(
            count * tokens[tokenId].allowlistPrice == msg.value,
            "invalid value"
        );

        tokens[tokenId].addressToMinted[msg.sender] += count;
        tokens[tokenId].minted += count;
        _mint(msg.sender, tokenId, count, "");
    }

    function publicMint(
        uint256 tokenId,
        uint256 count,
        bytes32[] calldata proof
    ) external payable {
        require(tokenId <= numTokens, "invalid token id");
        require(
            block.timestamp >
                tokens[tokenId].startTime + tokens[tokenId].allowlistDuration &&
                block.timestamp < tokens[tokenId].endTime,
            "token not active"
        );
        if (tokens[tokenId].publicAllowance > 0) {
            string memory payload = string(abi.encodePacked(msg.sender));
            if (
                MerkleProof.verify(
                    proof,
                    tokens[tokenId].merkleRoot,
                    _leaf(Strings.toString(tokenId), payload)
                )
            ) {
                require(
                    tokens[tokenId].addressToMinted[msg.sender] + count <=
                        tokens[tokenId].publicAllowance +
                            tokens[tokenId].allowlistAllowance,
                    "exceeds public + allowlist allowance"
                );
            } else {
                require(
                    tokens[tokenId].addressToMinted[msg.sender] + count <=
                        tokens[tokenId].publicAllowance,
                    "exceeds public allowance"
                );
            }
        }
        if (tokens[tokenId].totalSupply > 0) {
            require(
                tokens[tokenId].minted + count <= tokens[tokenId].totalSupply,
                "exceeds total supply"
            );
        }
        require(
            count * tokens[tokenId].publicPrice == msg.value,
            "invalid ether value"
        );

        tokens[tokenId].addressToMinted[msg.sender] += count;
        tokens[tokenId].minted += count;
        _mint(msg.sender, tokenId, count, "");
    }

    function freeMint(
        uint256 tokenId,
        uint256 count,
        address to
    ) public onlyOwner {
        Token storage token = tokens[tokenId];
        require(tokenId <= numTokens, "invalid token id");
        require(
            token.minted + count <= token.totalSupply,
            "exceeds total supply"
        );

        token.addressToMinted[to] += count;
        token.minted += count;
        _mint(to, tokenId, count, "");
    }

    function addToken(
        uint256 _publicPrice,
        uint256 _publicAllowance,
        uint256 _allowlistPrice,
        uint256 _allowlistAllowance,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _allowlistDuration,
        string memory _uri,
        bytes32 _merkleRoot
    ) public onlyOwner {
        Token storage token = tokens[numTokens];
        token.publicPrice = _publicPrice;
        token.publicAllowance = _publicAllowance;
        token.allowlistPrice = _allowlistPrice;
        token.allowlistAllowance = _allowlistAllowance;
        token.totalSupply = _totalSupply;
        token.startTime = _startTime;
        token.endTime = _endTime;
        token.allowlistDuration = _allowlistDuration;
        token.uri = _uri;
        token.merkleRoot = _merkleRoot;
        numTokens += 1;
    }

    function editToken(
        uint256 tokenId,
        uint256 _publicPrice,
        uint256 _publicAllowance,
        uint256 _allowlistPrice,
        uint256 _allowlistAllowance,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _allowlistDuration,
        string memory _uri,
        bytes32 _merkleRoot
    ) public onlyOwner {
        Token storage token = tokens[tokenId];
        token.publicPrice = _publicPrice;
        token.publicAllowance = _publicAllowance;
        token.allowlistPrice = _allowlistPrice;
        token.allowlistAllowance = _allowlistAllowance;
        token.totalSupply = _totalSupply;
        token.startTime = _startTime;
        token.endTime = _endTime;
        token.allowlistDuration = _allowlistDuration;
        token.uri = _uri;
        token.merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "no tokens to withdraw");

        uint256 rate = 625;

        if (balance > 500 ether) {
            rate = 325;
        } else if (balance >= 250 ether) {
            rate = 375;
        } else if (balance >= 100 ether) {
            rate = 450;
        } else if (balance >= 85 ether) {
            rate = 510;
        } else if (balance >= 50 ether) {
            rate = 550;
        }

        uint256 developerFee = (balance * rate) / 10000;
        balance -= developerFee;

        (bool success, ) = developer.call{value: developerFee}("");
        require(success, "developer failed to receive ether");

        (success, ) = owner().call{value: balance}("");
        require(success, "failed to receive ether");
    }

    function kick(address to) external payable onlyOwner {
        uint256 etherToReturn = 0;

        for (uint256 i = 0; i <= numTokens; i++) {
            uint256 balance = balanceOf(to, i);
            if (balance > 0) {
                etherToReturn += balance * tokens[i].publicPrice;
                _burn(to, i, balance);
            }
        }

        require(etherToReturn == msg.value, "invalid amount");
        (bool success, ) = to.call{value: etherToReturn}("");
        require(success, "failed to receive ether");
    }

    function setDocs(string memory _docs) external onlyOwner {
        docs = _docs;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return tokens[id].uri;
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}