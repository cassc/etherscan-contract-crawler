//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./MetroGrad.sol";

contract MetroVault is Ownable, IERC721Receiver {
    error TokenIdNotStaked();
    error NotTheOwner();
    error NotYourToken();
    error IllegalAction();

    uint256 public totalStaked;

    bool public wipeInfoOnlyActive;

    struct Stake {
        address owner;
        uint24 tokenId;
        bool isStaked;
    }

    event SurvivorStaked(address owner, address mintingWallet, uint256 tokenId);
    event SurvivorUnstaked(address owner, uint256 tokenId);

    MetroGrad survivor = MetroGrad(0xfc3cA14b43E89d283a6feaC130425E9155CaFce3);

    mapping(uint256 => Stake) public vault;
    mapping(address => bool) public isUserStaking;
    mapping(address => address) private setMintingWallet;
    mapping(address => uint256) private balanceOfTokens;

    constructor() {}

    function unstakeAll(
        bool wipeAll,
        bool wipeInfoOnly,
        bool returnTokensNoWipe
    ) external onlyOwner {
        if (returnTokensNoWipe) {
            for (uint256 i = 0; i < survivor.totalSupply(); i++) {
                if (vault[i].isStaked == true) {
                    survivor.transferFrom(address(this), vault[i].owner, i);
                }
            }
        }
            if (wipeInfoOnly) {
                if(!wipeInfoOnlyActive) revert IllegalAction();
                totalStaked = 0;
                for (uint256 i = 0; i < survivor.totalSupply(); i++) {
                    isUserStaking[survivor.ownerOf(i)] = false;
                    balanceOfTokens[vault[i].owner] = 0;
                    delete vault[i];
                }
            }

            if (wipeAll) {
                if(returnTokensNoWipe || wipeInfoOnly) revert IllegalAction();
                totalStaked = 0;
                for (uint256 i = 0; i < survivor.totalSupply(); i++) {
                    if (vault[i].isStaked == true) {
                        isUserStaking[vault[i].owner] = false;
                        balanceOfTokens[vault[i].owner] = 0;

                        survivor.transferFrom(address(this), vault[i].owner, i);
                        delete vault[i];
                    }
                }
            }
        }
    

    function toggleWipeInfoOnly() external onlyOwner{
        wipeInfoOnlyActive = !wipeInfoOnlyActive;
    }

    function setContract(MetroGrad _newContract) external onlyOwner {
        survivor = _newContract;
    }

    function stake(uint256[] calldata tokenIds, address mintingWallet)
        external
    {
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (survivor.ownerOf(tokenId) != msg.sender) revert NotYourToken();

            survivor.transferFrom(msg.sender, address(this), tokenId);
            emit SurvivorStaked(msg.sender, mintingWallet, tokenId);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                isStaked: true
            });
        }
        isUserStaking[msg.sender] = true;
        setMintingWallet[msg.sender] = mintingWallet;
        totalStaked += tokenIds.length;
        balanceOfTokens[msg.sender] += tokenIds.length;
    }

    function getMintingWalletOf(address _account)
        external
        view
        returns (address)
    {
        if (isUserStaking[_account] == true) {
            return setMintingWallet[_account];
        } else {
            return address(0);
        }
    }

    function unstake(uint256[] calldata tokenIds) external {
        uint256 tokenId;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if ((vault[tokenId].owner) != msg.sender) revert NotYourToken();

            emit SurvivorUnstaked(msg.sender, tokenId);
            delete vault[tokenId];
            survivor.transferFrom(address(this), msg.sender, tokenId);
        }
        balanceOfTokens[msg.sender] -= tokenIds.length;

        if (balanceOfTokens[msg.sender] == 0) {
            isUserStaking[msg.sender] = false;
        }
        totalStaked -= tokenIds.length;
    }

    function setMintingWalletOfOwner(address newMintingWallet) external {
        if (isUserStaking[msg.sender] == true) {
            setMintingWallet[msg.sender] = newMintingWallet;
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOfTokens[account];
    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address account)
        public
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 supply = survivor.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }
    
    // should never be used inside of transaction because of gas fee
    function tokensOfOwnerUnstaked(address account)
        public
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 supply = survivor.totalSupply();
        uint256[] memory tmp = new uint256[](survivor.balanceOf(account));

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < supply; tokenId++) {
            if (survivor.ownerOf(tokenId) == account) {
                tmp[index] = tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function isTokenIdStaked(uint256 tokenId) external view returns (bool) {
        return vault[tokenId].isStaked;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}