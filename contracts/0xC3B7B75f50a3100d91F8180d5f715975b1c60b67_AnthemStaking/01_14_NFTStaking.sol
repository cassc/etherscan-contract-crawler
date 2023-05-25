// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract AnthemStaking is ERC721, ReentrancyGuard, AccessControl {
    event Deposit(address indexed walletAddress, address indexed contractAddress, uint256 tokenId);
    event Withdraw(address indexed walletAddress, address indexed contractAddress, uint256 tokenId);

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct StakingNFT {
        address contractAddress;
        uint256 tokenId;
        uint256 depositTimestamp;
    }

    struct StakingUser {
        address walletAddress;
        uint256 tokenId;
        uint256 depositTimestamp;
    }

    address[] public contractAddressList;
    mapping(address => bool) public NFTContracts;

    mapping(address => StakingNFT[]) public depositNFTsByWalletAddress;
    mapping(address => StakingUser[]) public depositUsersByContractAddress;

    mapping(uint256 => StakingNFT) stakingNFTByCopyTokenId;
    mapping(address => mapping(uint256 => uint256)) tokenIdByCopyTokenId;

    uint256 public supply = 0;

    constructor() ERC721("ANTHEM Staking", "STAKE") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function addNFTContract(address _contractAddress) public onlyRole(ADMIN_ROLE) {
        NFTContracts[_contractAddress] = true;
        contractAddressList.push(_contractAddress);
    }

    function delNFTContract(address _contractAddress) public onlyRole(ADMIN_ROLE) {
        uint256 index;
        bool isExist = false;
        for (uint256 i = 0; i < contractAddressList.length; i++) {
            if (contractAddressList[i] == _contractAddress) {
                index = i;
                isExist = true;
                break;
            }
        }
        require(isExist, "This Contract Address is not registerd.");

        NFTContracts[_contractAddress] = false;
        for (uint256 i = index; i < contractAddressList.length - 1; i++) {
            contractAddressList[i] = contractAddressList[i + 1];
        }
        contractAddressList.pop();
    }

    function deposit(address _contractAddress, uint256 _tokenId) public nonReentrant {
        require(NFTContracts[_contractAddress], "Not supported Contract address");
        IERC721 token = IERC721(_contractAddress);
        require(msg.sender == tx.origin, "Not EOA");
        require(token.ownerOf(_tokenId) == msg.sender, "You are not the owner of NFT.");
        require(token.isApprovedForAll(msg.sender, address(this)), "permit yourself to let go");

        token.safeTransferFrom(msg.sender, address(this), _tokenId);

        uint256 nowTimestamp = block.timestamp;
        StakingNFT memory stake = StakingNFT({
            contractAddress: _contractAddress,
            tokenId: _tokenId,
            depositTimestamp: nowTimestamp
        });

        depositNFTsByWalletAddress[msg.sender].push(stake);

        depositUsersByContractAddress[_contractAddress].push(
            StakingUser({
                walletAddress: msg.sender,
                tokenId: _tokenId,
                depositTimestamp: nowTimestamp
            })
        );

        stakingNFTByCopyTokenId[supply + 1] = stake;
        tokenIdByCopyTokenId[_contractAddress][_tokenId] = supply + 1;
        _safeMint(msg.sender, supply + 1);
        supply++;

        emit Deposit(msg.sender, _contractAddress, _tokenId);
    }

    function withdraw(address _contractAddress, uint256 _tokenId) public nonReentrant {
        require(NFTContracts[_contractAddress], "Not supported Contract address");
        require(msg.sender == tx.origin, "Not EOA");

        StakingNFT[] storage depositNFTList = depositNFTsByWalletAddress[msg.sender];
        uint256 depositNFTsIndex = 0;
        bool depositNFTListExist = false;
        while (depositNFTsIndex < depositNFTList.length) {
            if (
                depositNFTList[depositNFTsIndex].contractAddress == _contractAddress &&
                depositNFTList[depositNFTsIndex].tokenId == _tokenId
            ) {
                depositNFTListExist = true;
                break;
            }

            depositNFTsIndex++;
        }

        StakingUser[] storage depositUserList = depositUsersByContractAddress[_contractAddress];
        uint256 depositUsersIndex = 0;
        bool depositUsersListExist = false;
        while (depositNFTsIndex < depositNFTList.length) {
            if (
                depositUserList[depositUsersIndex].walletAddress == msg.sender &&
                depositUserList[depositUsersIndex].tokenId == _tokenId
            ) {
                depositUsersListExist = true;
                break;
            }

            depositUsersIndex++;
        }

        require(depositNFTListExist && depositUsersListExist, "You have not deposit this");

        IERC721 token = IERC721(_contractAddress);
        token.safeTransferFrom(address(this), msg.sender, _tokenId);

        // delete walletaddress info
        require(depositNFTsIndex < depositNFTsByWalletAddress[msg.sender].length);
        depositNFTsByWalletAddress[msg.sender][depositNFTsIndex] = depositNFTsByWalletAddress[
            msg.sender
        ][depositNFTsByWalletAddress[msg.sender].length - 1];

        depositNFTsByWalletAddress[msg.sender].pop();

        // delete contractaddress info
        require(depositUsersIndex < depositUsersByContractAddress[_contractAddress].length);
        depositUsersByContractAddress[_contractAddress][
            depositUsersIndex
        ] = depositUsersByContractAddress[_contractAddress][
            depositUsersByContractAddress[_contractAddress].length - 1
        ];

        depositUsersByContractAddress[_contractAddress].pop();

        // copy burn
        uint256 copyTokenId = tokenIdByCopyTokenId[_contractAddress][_tokenId];
        _burn(copyTokenId);

        emit Withdraw(msg.sender, _contractAddress, _tokenId);
    }

    function getDepositNFTsByWalletAddress(address walletAddress)
        public
        view
        returns (StakingNFT[] memory)
    {
        StakingNFT[] memory depositInfo = new StakingNFT[](
            depositNFTsByWalletAddress[walletAddress].length
        );
        for (uint256 i = 0; i < depositNFTsByWalletAddress[walletAddress].length; i++) {
            StakingNFT storage stakingNFT = depositNFTsByWalletAddress[walletAddress][i];
            depositInfo[i] = stakingNFT;
        }
        return depositInfo;
    }

    function getDepositUsersByContractAddress(address contractAddress)
        public
        view
        returns (StakingUser[] memory)
    {
        StakingUser[] memory depositInfo = new StakingUser[](
            depositUsersByContractAddress[contractAddress].length
        );
        for (uint256 i = 0; i < depositUsersByContractAddress[contractAddress].length; i++) {
            StakingUser storage stakingUser = depositUsersByContractAddress[contractAddress][i];
            depositInfo[i] = stakingUser;
        }
        return depositInfo;
    }

    function getDepositUsersByContractAddressWithPaging(
        address contractAddress,
        uint256 pageSize,
        uint256 pageOfs
    ) public view returns (StakingUser[] memory) {
        uint256 max = depositUsersByContractAddress[contractAddress].length;
        uint256 ofs = pageSize * pageOfs;
        uint256 num = 0;
        if (ofs < max) {
            num = max - ofs;
            if (num > pageSize) {
                num = pageSize;
            }
        }

        StakingUser[] memory depositInfo = new StakingUser[](pageSize);
        for (uint256 i = 0; i < num; i++) {
            StakingUser storage stakingUser = depositUsersByContractAddress[contractAddress][
                ofs + i
            ];
            depositInfo[i] = stakingUser;
        }
        return depositInfo;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "This Copy NFT is burned.");
        IERC721Metadata token = IERC721Metadata(stakingNFTByCopyTokenId[_tokenId].contractAddress);

        return token.tokenURI(stakingNFTByCopyTokenId[_tokenId].tokenId);
    }

    function getContractAddressList() public view returns (address[] memory) {
        return contractAddressList;
    }

    function withdrawEth() external onlyRole(ADMIN_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 startTokenId
    ) internal override {
        require(from == address(0) || to == address(0), "transfer is prohibited");
        super._beforeTokenTransfer(from, to, startTokenId);
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("setApprovalForAll is prohibited");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("approve is prohibited");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}