# EPG_Analysis_SAS
Script for EPG Analysis, it is a modified version of Ebert program.
Main changes:
* Automatic import of all .ANA files from the folder. Eliminates the need of copy/pasting sections of the code for every file.
* Modifications for 12h recorging time.
* Implement automatic BoxCox transformation for all parameters. 
* Implement BY statement in PPROC GLIMMIX for automatic (and faster) analysis of all calculated parameters.
* Added functionaity to automatically export .csv summary containing untransformed means, min, and max with Tukey test letter grouping.
* At the end of analysis, add labels for all parameters for eassy readability (e.g.: DurNpFllwFrstSusE2 = Duration of NP following first sustained E2)


### References
Ebert, Timothy A., Elaine A. Backus, Miguel Cid, Alberto Fereres, and Michael E. Rogers. "A new SAS program for behavioral analysis of electrical penetration graph data." Computers and Electronics in Agriculture 116 (2015): 80-87. Harvard. Available at: http://doi.org/10.1016/j.compag.2015.06.011

Osborne, Jason W. "Improving your data transformations: Applying the Box-Cox transformation." Practical Assessment, Research & Evaluation 15, no. 12 (2010): 1-9. Available at: http://pareonline.net/pdf/v15n12.pdf
