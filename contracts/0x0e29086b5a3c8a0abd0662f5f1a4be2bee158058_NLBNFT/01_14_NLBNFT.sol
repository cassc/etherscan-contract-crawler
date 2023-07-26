// SPDX-License-Identifier: MIT
/**
                               ╓"^  ▐▒└       "∩╖
                          "Q▐   ▒    ▄▐       ╡└▌  ,█   ,
                       █    █µ  ▀└└           └▀  #▀▓   ╓╙▀
                 ²▄     ▀                              4⌐   └▀#
                  `█▄▀                                     ▄└    ,
                                                              ▄█▄└
          ╔└,                                                   '¬ ,#╙
            ▀▄▀                                                    ╙▄▄
       a▄╖▌▄                                                         ▄#"
         "▀                      , ╓█▄,                              "└
     "▀▄,                  ╓█    █▌╙████▄                             ,M"└▐
                         ,██▌   ╫██  ████ ██▀█▄▄▄▄,,                   ▀"
    µ▄▀▀               ,█████   ███ ▐██▀  ╟███▄▄▄▄╙╙▀╙╨╩▒▀ªwµ           K⌐▒▀
     └▀▀             ,██▀▐███▌  ███ ╟██     ▀██████████▄▄  └7V▌¥µ       *▀T`
                    ▄█▀  ▐████  ╫██ ╟██      ███       └██▌    └⌐▀▄
                   ██    ]█████ ╟██ ╟██     ████▄▄▄█████▀└     ^  "U
    ,             █▌      █████▄╟█▌ ▐██      ███████████▄▄ `≈,    ▄
    ▀`            █▄   %  ██▌╟████▌ ▐██      ██▌      └▀▀████, ''          ▀▀
                   ▀W▄«╛  ██▌ ████▌ ]██ ▐██▀▀██⌐           ╙▀██▄
                          ██▌  ███⌐  ██  ╟█████▀█            ╓██▌
       ,       ▌   ▀▄#    ██▌   ██   ██   ▀╙▀██████████████████▀        ,
    ,#░▄       ▌    ▌▀▄   ██▌    █#█▀█████▄╙▀▄▄▄╙▀███▀▀█▀▀▀▀▀└          ▄▄╝▀▀
    ╙'         █    ▌ ╙   ██    ▀  █▄██.╙▀███▄    ]█ε                     '"
     ƒ` ,▌      ▀    ▀▄▄▄█▀`   ▐    └' ╟▌  ╙▀███████                  ^▀╗▄
     '^└          ▀w, ,▄▀       ▀▄µ,,▄█▀       └╙└'                  ▄
        ,▄▀└                      '└└                               ╗╥╜Σ▄
            ▄▀                                                    #▄  "¬
            ,#▀                                                  └ *└¥
           └'  á╖▄                                                  "
              ╝▀.   ▄                                     ,▄█
                 ╓ ╜    ▄                              ▄  "  ▀▄
                  ╙▀   á.  ▐ ╓                     ▄    █
                      ╙▀   ╫╩`  ▌║⌐      #▀ε  └└µ  ▌▀    ▀
                           └   ▐░▌       '"▄   ,ì  ╙ '
                                          └
*/
//  * 0xCursed
//  * Credits: @nftchance & @masonnft @squeebo_nft

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721Enumerable.sol";

contract NLBNFT is ERC721Enumerable, Ownable {
    string public baseURI;

    address public proxyRegistryAddress;
    address public immutable teamWallet;

    bytes32 public whitelistMerkleRoot;
    uint256 public MAX_SUPPLY;
    string public constant baseExtension = ".json";

    uint256 public constant MAX_PER_TX = 6;
    uint256 public constant RESERVES = 50;
    uint256 public constant publicPrice = 0.07 ether;
    uint256 public constant whitelistPrice = 0.07 ether;

    bool public isPublicSale;

    mapping(address => bool) public projectProxy;
    mapping(address => uint256) public addressToMinted;

    constructor(
        string memory _baseURI,
        address _proxyRegistryAddress,
        address _teamWallet
    ) ERC721("NLBNFT", "NLB") {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        teamWallet = _teamWallet;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setMaxSupply(uint256 _MAX_SUPPLY) external onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    baseExtension
                )
            );
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress)
        external
        onlyOwner
    {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        projectProxy[proxyAddress] = !projectProxy[proxyAddress];
    }

    function collectReserves() external onlyOwner {
        require(_owners.length == 0, "Reserves already taken.");
        for (uint256 i; i < RESERVES; i++) _mint(_msgSender(), i);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function togglePublicSale() external onlyOwner {
        delete whitelistMerkleRoot;
        isPublicSale = !isPublicSale;
    }

    function _leaf(string memory allowance, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function getAllowance(string memory allowance, bytes32[] calldata proof)
        public
        view
        returns (string memory)
    {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(_leaf(allowance, payload), proof),
            "Invalid Merkle Tree proof supplied."
        );
        return allowance;
    }

    function whitelistMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        uint256 totalSupply = _owners.length;
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(totalSupply + count < MAX_SUPPLY, "Exceeds max supply.");
        require(count * whitelistPrice == msg.value, "Invalid funds provided.");
        require(
            _verify(_leaf(Strings.toString(allowance), payload), proof),
            "Invalid Merkle Tree proof supplied."
        );
        require(
            addressToMinted[_msgSender()] + count <= allowance,
            "Exceeds whitelisted Allowance"
        );

        addressToMinted[_msgSender()] += count;
        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function publicMint(uint256 count) public payable {
        uint256 totalSupply = _owners.length;
        require(isPublicSale, "Public sale is not live");
        require(totalSupply + count < MAX_SUPPLY, "Exceeds max supply.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        require(count * publicPrice == msg.value, "Invalid funds provided.");

        for (uint256 i; i < count; i++) {
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }

    function withdraw() public {
        (bool success, ) = teamWallet.call{value: address(this).balance}("");
        require(success, "Failed to send to Team.");
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory data_
    ) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
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
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            projectProxy[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}