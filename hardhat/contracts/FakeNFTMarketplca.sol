// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FakeNFTMarketplace{
    //mapping of token to the owner
    mapping (uint256 => address) public tokens;

    uint256 nftPrice = 0.1 ether;

    //purchasing nft 
    function purchase(uint256 _tokenID)external payable{
        require(msg.value ==nftPrice,"This NFT cost 0.1 ether");
        tokens[_tokenID] = msg.sender;
    }

    //get the nft price
    function getPrice() external view returns(uint256){
        return nftPrice;
    }

    //checking whether the given tokenid is already sold or not
    function available(uint256 _tokenID) external view returns(bool){
        //address(0) = 0x0000000000000000000000000000000000000000
        //This is the defalut value for address in solidity
        if(tokens[_tokenID] == address(0)){
            return true;
        }
        return false;


    }



}