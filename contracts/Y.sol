pragma solidity 0.4.19;

contract Y {
    address payee;
    Proportion public donationProportion;
    struct Proportion {
        uint num; // numerator
        uint denom; // denominator
    }

    function Y(uint num, uint denom) public {
        require(0 < num && num < denom); // 0 < num/denom < 1
        donationProportion = Proportion(num, denom);
        payee = msg.sender;
    }

    function payAndDonate(uint num, uint denom, address donee) public payable { // TODO Is returning bool necessary?
        require(num == donationProportion.num && denom == donationProportion.denom);
        uint donation = (msg.value * donationProportion.num) / donationProportion.denom;
        payee.transfer(msg.value - donation);
        donee.transfer(donation);
    }

    function setDonationProportion(uint num, uint denom) public {
        require(0 < num && num < denom); // 0 < num/denom < 1
        require(msg.sender == payee);
        donationProportion = Proportion(num, denom);
    }
}
