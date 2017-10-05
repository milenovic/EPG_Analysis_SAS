# EPG_Analysis_SAS
SAS program for parameter calculation and statistical analysis of Electrical Penetration Graph (EPG) recordings. This is a modified version of Ebert 3.0 program for DC recorded whiteflies.

### Main changes:
* Automatic import of all .ANA files from the folder. Eliminates the need of copy/pasting sections of the code for every file.
* All input/output statements moved to the beginning to be more user friendly.
* Modifications to allow 12h recorging time to variables that are by hour.
* Implement automatic BoxCox transformation for all parameters.
* Added option to show transformation results (selected λ, residuals, Q-Q plots, etc.)
* Implement BY statement in PPROC GLIMMIX for automatic (and faster) analysis of all calculated parameters.
* Added functionaity to automatically export .csv summary containing untransformed means, min, and max with Tukey test letter grouping.
* At the end of analysis, add labels for all parameters for easy readability (e.g.: DurNpFllwFrstSusE2 = Duration of NP following first sustained E2)

### TO DO
* Make error checker display results in more user friendly way.
* Further optimizations for speed.

### References
Ebert, Timothy A., Elaine A. Backus, Miguel Cid, Alberto Fereres, and Michael E. Rogers. "A new SAS program for behavioral analysis of electrical penetration graph data." Computers and Electronics in Agriculture 116 (2015): 80-87. Harvard. Available at: http://doi.org/10.1016/j.compag.2015.06.011

Osborne, Jason W. "Improving your data transformations: Applying the Box-Cox transformation." Practical Assessment, Research & Evaluation 15, no. 12 (2010): 1-9. Available at: http://pareonline.net/pdf/v15n12.pdf
