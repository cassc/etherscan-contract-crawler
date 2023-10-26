// SPDX-License-Identifier: MIT

// BY @0XDAVZER FOR KLUBX. Special Thanks to @SamuelCardillo
//               ,--,
//        ,--.,---.'|
//    ,--/  /||   | :                    ,---,. ,--,     ,--,
// ,---,': / ':   : |            ,--,  ,'  .'  \|'. \   / .`|
// :   : '/ / |   ' :          ,'_ /|,---.' .' |; \ `\ /' / ;
// |   '   ,  ;   ; '     .--. |  | :|   |  |: |`. \  /  / .'
// '   |  /   '   | |__ ,'_ /| :  . |:   :  :  / \  \/  / ./
// |   ;  ;   |   | :.'||  ' | |  . .:   |    ;   \  \.'  /
// :   '   \  '   :    ;|  | ' |  | ||   :     \   \  ;  ;
// |   |    ' |   |  ./ :  | | :  ' ;|   |   . |  / \  \  \
// '   : |.  \;   : ;   |  ; ' |  | ''   :  '; | ;  /\  \  \
// |   | '_\.'|   ,/    :  | : ;  ; ||   |  | ;./__;  \  ;  \
// '   : |    '---'     '  :  `--'   \   :   / |   : / \  \  ;
// ;   |,'              :  ,      .-./   | ,'  ;   |/   \  ' |
// '---'                 `--`----'   `----'    `---'     `--`

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "https://github.com/chiru-labs/ERC721A/blob/2342b592d990a7710faf40fe66cfa1ce61dd2339/contracts/ERC721A.sol";

contract KlubX is ERC721A, DefaultOperatorFilterer, Ownable {
    string public _baseTokenURI;
    uint256 public _totalWhitelist;
    uint256 public _itemByWallet = 1;
    bool public _canBeTransferred = false;
    mapping(address => bool) public _authorizedContracts;
    bytes32 public merkleRoot;
    mapping (address => bool) _authorizedAirdropper;

    constructor(string memory baseTokenURI, uint256 totalWhitelist)
        ERC721A("KlubX", "KBX")
    {
        _baseTokenURI = baseTokenURI;
        _totalWhitelist = totalWhitelist;

        _authorizedContracts[0x0000000000000000000000000000000000000000] = true; // Allowing aidrop while keeping soulbound feature
        _authorizedAirdropper[msg.sender] = true; // Allowing the deployer to airdrop
    }

        modifier onlyAirdropper() {
            require(_authorizedAirdropper[msg.sender]);
            _;
        }

    function isWhitelisted(
        address walletAddress,
        bytes32[] calldata merkleLeafs
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                merkleLeafs,
                merkleRoot,
                keccak256(abi.encodePacked(walletAddress))
            );
    }

    function airdropToken(
        address[] memory whitelisted,
        bytes32[][] calldata merkleLeafs
    ) external onlyAirdropper {
        require(
            totalSupply() + 1 <= _totalWhitelist,
            "ERC721A-KBX: Max supply has been reached"
        );

        uint256 length = whitelisted.length;
        for (uint256 i = 0; i < length; i++) {
            require(
                isWhitelisted(whitelisted[i], merkleLeafs[i]),
                "Address is not whitelisted"
            );
            require(
                numberMinted(whitelisted[i]) + _itemByWallet <= _itemByWallet,
                "Item by wallet has been overflown"
            );

            _safeMint(whitelisted[i], 1);
        }
    }

    // ** OVERRIDE //

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(
            _canBeTransferred || _authorizedContracts[from],
            "ERC721A-KBX: Non transferable token"
        );
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function isAbleToAirdrop (address userAddress) public view returns (bool) {
        return _authorizedAirdropper[userAddress];
    }

    // OWNER

    function setTransferable(bool canBeTransferred) public onlyOwner {
        _canBeTransferred = canBeTransferred;
    }

    function setTotalWhitelist(uint256 totalWhitelist) public onlyOwner {
        _totalWhitelist = totalWhitelist;
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setAuthorizedContract(address contractAddress) public onlyOwner {
        _authorizedContracts[contractAddress] = true;
    }

    function setAuthorizedAirdropper(address userAddress) public onlyOwner {
        _authorizedAirdropper[userAddress] = true;
    }

    // WITHDRAW

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /////////////////////////////
    // OPENSEA FILTER REGISTRY
    /////////////////////////////

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        require(
            _canBeTransferred || _authorizedContracts[operator],
            "ERC721A-KLBX : Can't be transferred"
        ); // Additional check on top of OpenSea
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        require(
            _canBeTransferred || _authorizedContracts[operator],
            "ERC721A-KLBX : Can't be transferred"
        ); // Additional check on top of OpenSea
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}