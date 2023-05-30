// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//import ERC1155
import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./_ecdsa.sol";

contract SupplyCrate is ERC1155, Ownable, DefaultOperatorFilterer {
    string tokenUri = "https://kira-nft-data.s3.amazonaws.com/lootbox/1";
    address public signer = 0xaC48A436cD212E5476ab270c881332A9cd0FCa7A;
    uint256 public price = 0.001 ether;
    mapping (address => bool) public claimed;
    bool public isOpen;
    bool public claimsOpen;

    constructor() ERC1155("KiraCorp Supply Crate") {}

    function flipClaimsOpen() external onlyOwner {
        claimsOpen = !claimsOpen;
    }

    function flipOpen() external onlyOwner {
        isOpen = !isOpen;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setURI(string memory _uri) public onlyOwner {
        tokenUri = _uri;
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return tokenUri;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function claim(bytes calldata signature) external {
        require(claimsOpen, "Claims not open");
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        require(_validateData(msg.sender, signature), "Invalid signature");
        _mint(msg.sender, 1, 1, "");
    }

    function mintPublic(uint256 amount) external payable {
        require(isOpen, "Not open");
        require(amount * price == msg.value, "Incorrect amount of ETH sent");
        _mint(msg.sender, 1, amount, "");
    }

    function ownerMint(address to, uint256 amount) external onlyOwner {
        _mint(to, 1, amount, "");
    }

    function airdrop(address[] calldata to) external onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], 1, 1, "");
        }
    }

    function saveTokens(IERC20 tokenAddress, uint256 amount) external onlyOwner() {
        SafeERC20.safeTransfer(tokenAddress, owner(), amount == 0 ? tokenAddress.balanceOf(address(this)) : amount);
    }
    
    function saveETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeBatchTransferFrom(from, to, tokenIds, amounts, data);
    }

    function _validateData(
        address _user,
        bytes calldata signature
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(_user));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signer);
    }
}